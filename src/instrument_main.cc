#include <err.h>
#include <fcntl.h>		// open
#include <libgen.h>
#include <string.h>
#include <stdlib.h>		// mkstemp, getenv
#include <stdio.h>		// tmpnam
#include <unistd.h>		// fork
#ifdef __gnu_linux__
 #include <bsd/stdlib.h>			// setprogname
#endif
#include <sys/wait.h>		// waitpid

#include <fstream>
#include <iostream>
#include <sstream>
#include <string>

#include <clang/Tooling/CommonOptionsParser.h>
#include <clang/Tooling/Tooling.h>

#include "instrument_action.h"

#define STR_EXPAND(tok) #tok
#define STR(tok) STR_EXPAND(tok)

static llvm::cl::OptionCategory ToolingCategory("instrument options");

void
clean_path()
{
	char *scv_path = getenv("CITRUN_PATH");
	char *path = getenv("PATH");
	if (scv_path == NULL)
		errx(1, "CITRUN_PATH not found in environment, not running "
			"native compiler");
	else if (path == NULL)
		errx(1, "PATH not set, your build system needs to use "
			"the PATH for this tool to be useful.");

	// Filter CITRUN_PATH out of PATH
	std::stringstream path_ss(path);
	std::ostringstream new_path;
	std::string component;
	bool first_component = 1;

	while (std::getline(path_ss, component, ':')) {
		if (component.compare(scv_path) == 0)
			continue;

		if (first_component == 0)
			new_path << ":";

		// It wasn't $CITRUN_PATH, keep it
		new_path << component;
		first_component = 0;
	}

	// Set new $PATH
	setenv("PATH", new_path.str().c_str(), 1);
}

int
instrument(int argc, char *argv[], std::vector<std::string> const &source_files)
{
	if (source_files.size() == 0)
		return 0;

	std::vector<const char *> clang_argv;
	clang_argv.push_back(argv[0]);
	for (auto s : source_files)
		clang_argv.push_back(s.c_str());

	clang_argv.push_back("--");

	// Append original command line verbatim
	clang_argv.insert(clang_argv.end(), argv, argv + argc);

	// When instrumenting certain code clang sometimes needs its own include
	// files. These are defined globally per platform.
	clang_argv.push_back(STR(CLANG_INCL));

	// give clang it's <source files> -- <native command line> arg style
	int clang_argc = clang_argv.size();
	clang::tooling::CommonOptionsParser op(clang_argc, &clang_argv[0], ToolingCategory);
	clang::tooling::ClangTool Tool(op.getCompilations(), op.getSourcePathList());

	// ClangTool::run accepts a FrontendActionFactory, which is then used to
	// create new objects implementing the FrontendAction interface. Here we
	// use the helper newFrontendActionFactory to create a default factory
	// that will return a new MyFrontendAction object every time.  To
	// further customize this, we could create our own factory class.
	// int ret = Tool.run(new MFAF(inst_files));
#if LLVM_VER > 34
	int ret = Tool.run(&(*clang::tooling::newFrontendActionFactory<InstrumentAction>()));
#else
	int ret = Tool.run(clang::tooling::newFrontendActionFactory<InstrumentAction>());
#endif
	return ret;
}

bool
ends_with(std::string const &value, std::string const &suffix)
{
	if (suffix.length() > value.length())
		return false;

	return std::equal(suffix.rbegin(), suffix.rend(), value.rbegin());
}

void
copy_file(std::string dst_fn, std::string src_fn)
{
	std::ifstream src(src_fn, std::ios::binary);
	std::ofstream dst(dst_fn, std::ios::binary);

	dst << src.rdbuf();
}

int
main(int argc, char *argv[])
{
	// Set a better name than the symlink that was used to find this program
	setprogname("citrun_instrument");
	clean_path();

	std::vector<char *> args(argv, argv + argc);
	std::vector<std::string> source_files;
	std::map<std::string, std::string> temp_file_map;
	// Keep track of some "well known" compiler flags for later.
	bool object_arg = false;
	bool compile_arg = false;

	// Necessary because we're going to pass argv to execvp
	argv[argc] = NULL;

	for (auto &arg : args) {
		if (strcmp(arg, "-E") == 0) {
			// Preprocessing argument found, exec native command
			if (execvp(argv[0], argv))
				err(1, "execvp");
		}
		else if (strcmp(arg, "-o") == 0)
			object_arg = true;
		else if (strcmp(arg, "-c") == 0)
			compile_arg = true;

		// Find source files
		if (ends_with(arg, ".c") || ends_with(arg, ".cc") ||
		    ends_with(arg, ".cpp") || ends_with(arg, ".cxx")) {

			// Keep track of original source file names
			source_files.push_back(arg);

			if (getenv("CITRUN_LEAVE_MODIFIED_SRC"))
				// Don't copy and restore original source files
				continue;

			char *dst_fn;
			if ((dst_fn = tmpnam(NULL)) == NULL)
				err(1, "tmpnam");

			copy_file(dst_fn, arg);
			temp_file_map[arg] = dst_fn;
		}
	}

	if (instrument(argc, argv, source_files)) {
		// If instrumentation failed, then modified source files were
		// not written. So no need to replace them.
		warnx("Instrumentation failed, running unmodified command.");
		if (execvp(argv[0], argv))
			err(1, "execvp");
	}

	bool linking = false;
	if (!object_arg && !compile_arg && source_files.size() > 0)
		// Assume single line a.out compilation
		// $ gcc main.c
		linking = true;
	else if (object_arg && !compile_arg)
		// gcc -o main main.o fib.o while.o
		// gcc -o main main.c fib.c
		linking = true;

	std::string last_node_path("LAST_NODE");
	if (linking) {
		if (access(last_node_path.c_str(), F_OK)) {
			// Couldn't access the LAST_NODE file, we cannot link
			// to the runtime library without it.
			warnx("LAST_NODE file not found.");
			if (execvp(argv[0], argv))
				err(1, "execvp");
		}

		std::ifstream last_node_ifstream;
		std::string last_node;

		last_node_ifstream.open(last_node_path, std::fstream::in);
		last_node_ifstream >> last_node;
		last_node_ifstream.close();

		// We need to link the entry point in the runtime to the
		// instrumented application. OS independent.
		std::stringstream defsym_arg;
#ifdef __APPLE__
		defsym_arg << "-Wl,-alias,__citrun_node_";
		defsym_arg << last_node;
		defsym_arg << ",__citrun_tu_head";
#else
		defsym_arg << "-Wl,--defsym=_citrun_tu_head=_citrun_node_";
		defsym_arg << last_node;
#endif

		// Add the runtime library and the symbol define hack
		// automatically to the command line
		args.push_back(strdup(defsym_arg.str().c_str()));
		args.push_back(const_cast<char *>(STR(LIBCITRUN_PATH)));
	}

	// Instrumentation succeeded. Run the native compiler with a modified
	// command line.
	args.push_back(NULL);

	pid_t child_pid;
	if ((child_pid = fork()) < 0)
		err(1, "fork");

	if (child_pid == 0) {
		// In child
		if (execvp(args[0], &args[0]))
			err(1, "execvp");
	}

	int status;
	if (waitpid(child_pid, &status, 0) < 0)
		err(1, "waitpid");

	for (auto &tmp_file : temp_file_map) {
		copy_file(tmp_file.first, tmp_file.second);
		unlink(tmp_file.second.c_str());
	}

	if (linking)
		unlink(last_node_path.c_str());
}
