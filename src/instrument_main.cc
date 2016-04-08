#include <err.h>
#include <libgen.h>
#include <string.h>
#include <unistd.h>
#ifdef __gnu_linux__
 #include <bsd/stdlib.h>			// setprogname
#endif

#include <fstream>
#include <iostream>
#include <sstream>
#include <string>

#include <clang/Tooling/CommonOptionsParser.h>
#include <clang/Tooling/Tooling.h>

#include "instrument_action.h"

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
	if (ret)
		warnx("Instrumentation failed");
	return ret;
}

bool
ends_with(std::string const &value, std::string const &suffix)
{
	if (suffix.length() > value.length())
		return false;

	return std::equal(suffix.rbegin(), suffix.rend(), value.rbegin());
}

int
main(int argc, char *argv[])
{
	// Set a better name than the symlink that was used to find this program
	setprogname("citrun_instrument");
	clean_path();

	std::vector<std::string> args(argv, argv + argc);
	std::vector<std::string> source_files;
	std::vector<char *> modified_args;
	// Keep track of some "well known" compiler flags for later.
	bool object_arg = false;
	bool compile_arg = false;

	// We're going to be passing argv to execvp
	argv[argc] = NULL;

	for (auto &arg : args) {
		if (arg.compare("-E") == 0) {
			// Preprocessing arument found, exec native command
			if (execvp(argv[0], argv))
				err(1, "execvp");
		}
		else if (arg.compare("-o") == 0)
			object_arg = true;
		else if (arg.compare("-c") == 0)
			compile_arg = true;

		// Find source files
		if (ends_with(arg, ".c") || ends_with(arg, ".cc") ||
		    ends_with(arg, ".cpp") || ends_with(arg, ".cxx")) {

			// Keep track of original source file names
			source_files.push_back(arg);

			// Find original directory or "." if relative path
#ifdef __OpenBSD__
			char *src_dir = dirname(arg.c_str());
#else
			char *src_dir = dirname(strdup(arg.c_str()));
#endif
			if (src_dir == NULL)
				err(1, "dirname");
#ifdef __OpenBSD__
			char *src_name = basename(arg.c_str());
#else
			char *src_name = basename(strdup(arg.c_str()));
#endif
			if (src_name == NULL)
				err(1, "basename");

			// modified_args will hang onto the contents of this
			std::string *inst_src_path = new std::string();
			inst_src_path->append(src_dir);
			inst_src_path->append("/inst/");
			inst_src_path->append(src_name);

			// Switch the original file name with the instrumented
			// one.
			modified_args.push_back(&(*inst_src_path)[0]);
			continue;
		}

		// Non source file argument, copy verbatim
		modified_args.push_back(const_cast<char *>(arg.c_str()));
	}

	// Instrument source files found on the command line
	if (instrument(argc, argv, source_files)) {
		warnx("instrumentation failed, running unmodified command");
		if (execvp(argv[0], argv))
			err(1, "execvp");
	}

	bool linking = false;
	// -o with -c means output object file
	// -o without -c means output binary
	if (!object_arg && !compile_arg && source_files.size() > 0)
		// Assume single line a.out compilation
		// $ gcc main.c
		linking = true;
	else if (object_arg && !compile_arg)
		// gcc -o main main.o fib.o while.o
		// gcc -o main main.c fib.c
		linking = true;

	if (linking) {
		std::string last_node_path("LAST_NODE");
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

		std::stringstream defsym_arg;
		defsym_arg << "-Wl,--defsym=_citrun_tu_head=_citrun_node_";
		defsym_arg << last_node;

		// Add the runtime library and the symbol define hack
		// automatically to the command line
		modified_args.push_back(strdup(defsym_arg.str().c_str()));
		modified_args.push_back(const_cast<char *>("/home/kyle/citrun/lib/libcitrun.so.0.0"));
	}

	// Instrumentation succeeded. Run the native compiler with a modified
	// command line.
	modified_args.push_back(NULL);
	if (execvp(modified_args[0], &modified_args[0]))
		err(1, "execvp");
}
