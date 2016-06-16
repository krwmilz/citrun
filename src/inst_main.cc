#include <err.h>
#include <fcntl.h>		// open
#include <libgen.h>
#include <string.h>
#include <stdlib.h>		// mkstemp, getenv
#include <stdio.h>		// tmpnam
#include <unistd.h>		// fork
#ifdef __gnu_linux__
 #include <bsd/stdlib.h>	// setprogname
#endif
#include <sys/stat.h>		// stat
#include <sys/time.h>		// utimes
#include <sys/wait.h>		// waitpid

#include <fstream>
#include <iostream>
#include <sstream>
#include <string>

#include <clang/Tooling/CommonOptionsParser.h>
#include <clang/Tooling/Tooling.h>

#include "inst_action.h"
#include "runtime_h.h"

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
copy_file(std::string const &dst_fn, std::string const &src_fn)
{
	struct stat sb;
	struct timeval st_tim[2];

	// Save original access and modification times
	stat(src_fn.c_str(), &sb);
#ifdef __APPLE__
	TIMESPEC_TO_TIMEVAL(&st_tim[0], &sb.st_atimespec);
	TIMESPEC_TO_TIMEVAL(&st_tim[1], &sb.st_mtimespec);
#else
	TIMESPEC_TO_TIMEVAL(&st_tim[0], &sb.st_atim);
	TIMESPEC_TO_TIMEVAL(&st_tim[1], &sb.st_mtim);
#endif

	std::ifstream src(src_fn, std::ios::binary);
	std::ofstream dst(dst_fn, std::ios::binary);

	dst << src.rdbuf();

	src.close();
	dst.close();

	// Restore the original access and modification time
	utimes(dst_fn.c_str(), st_tim);
}

void
restore_original_src(std::map<std::string, std::string> const &temp_file_map)
{
	for (auto &tmp_file : temp_file_map) {
		copy_file(tmp_file.first, tmp_file.second);
		unlink(tmp_file.second.c_str());
	}
}

void
patch_link_command(std::vector<char *> &args)
{
	std::string inst_files_list("INSTRUMENTED");

	if (access(inst_files_list.c_str(), F_OK)) {
		warnx("No instrumented object files found.");
		if (execvp(args[0], &args[0]))
			err(1, "execvp");
	}

	// std::cerr << "Link detected. Arguments are:" << std::endl;
	// for (auto &arg : args)
	// 	std::cerr << "  '" << arg << "', " << std::endl;

	std::vector<std::string> instrumented_files;
	std::ifstream inst_files_ifstream(inst_files_list);

	std::string temp_line;
	while (std::getline(inst_files_ifstream, temp_line))
		instrumented_files.push_back(temp_line);

	inst_files_ifstream.close();

	// std::cerr << "Instrumented object files are:" << std::endl;
	// for (auto &line : instrumented_files)
	// 	std::cerr << "  '" << line << "', " << std::endl;

	std::ofstream patch_ofstream("citrun_patch.c");

	// Inject the runtime header.
	patch_ofstream << runtime_h << std::endl;

	for (auto &line : instrumented_files)
		patch_ofstream << "extern struct citrun_node citrun_node_" << line << ";" << std::endl;

	int num_tus = instrumented_files.size();
	patch_ofstream << "struct citrun_node *citrun_nodes[";
	patch_ofstream << num_tus << "] = {" << std::endl;

	for (auto &line : instrumented_files)
		patch_ofstream << "\t&citrun_node_" << line << ", " << std::endl;
	patch_ofstream << "};" << std::endl;

	patch_ofstream << "uint64_t citrun_nodes_total = " << num_tus << ";" << std::endl;
	patch_ofstream.close();

	args.push_back(const_cast<char *>("citrun_patch.c"));

	char *lib_str;
	if ((lib_str = getenv("CITRUN_LIB")) == NULL)
		errx(1, "CITRUN_LIB not found in environment.");

	// Add the runtime library and the symbol define hack
	// automatically to the command line
	args.push_back("-pthread");
	args.push_back(lib_str);
}

int
main(int argc, char *argv[])
{
	// Set a better name than the symlink that was used to find this program
	setprogname("citrun-inst");
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
		warnx("Instrumentation failed, compiling unmodified code.");

		// It seems necessary right now to do this.
		restore_original_src(temp_file_map);

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

	if (linking) {
		patch_link_command(args);
	}

	// Instrumentation succeeded. Run the native compiler with a possibly
	// modified command line.
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

	restore_original_src(temp_file_map);

	if (linking)
		unlink("citrun_patch.c");
}
