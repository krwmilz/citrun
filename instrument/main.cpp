#include <err.h>
#include <libgen.h>
#include <stdlib.h>
#include <unistd.h>

#include <fstream>
#include <iostream>
#include <sstream>
#include <string>

#include <clang/Tooling/CommonOptionsParser.h>
#include <clang/Tooling/Tooling.h>
#include <clang/Rewrite/Core/Rewriter.h>
#include <llvm/Support/raw_ostream.h>

#include "instrumenter.h"

using namespace clang;
using namespace clang::tooling;

static llvm::cl::OptionCategory ToolingCategory("instrument options");

void
clean_path()
{
	char *scv_path = getenv("SCV_PATH");
	char *path = getenv("PATH");
	if (scv_path == NULL)
		errx(1, "SCV_PATH not found in environment, not running "
			"native compiler");
	else if (path == NULL)
		errx(1, "PATH not set, your build system needs to use "
			"the PATH for this tool to be useful.");

	// Filter SCV_PATH out of PATH
	std::stringstream path_ss(path);
	std::ostringstream new_path;
	std::string component;
	bool first_component = 1;

	while (std::getline(path_ss, component, ':')) {
		if (component.compare(scv_path) == 0)
			continue;

		if (first_component == 0)
			new_path << ":";

		// It wasn't $SCV_PATH, keep it
		new_path << component;
		first_component = 0;
	}

	// Set new $PATH
	setenv("PATH", new_path.str().c_str(), 1);
}

void
instrument(int argc, char *argv[], std::vector<std::string> &source_files)
{
	const char *clang_argv[source_files.size() + 1 + argc];
	int clang_argc = 0;

	clang_argv[clang_argc++] = argv[0];
	for (auto s : source_files)
		clang_argv[clang_argc++] = s.c_str();

	clang_argv[clang_argc++] = "--";

	// append original command line verbatim after --
	for (int i = 0; i < argc; i++)
		clang_argv[clang_argc++] = argv[i];

#ifdef DEBUG
	// print out
	for (int i = 0; i < clang_argc; i++)
		std::cout << clang_argv[i] << " ";
	std::cout << std::endl;
#endif

	// give clang it's <source files> -- <native command line> arg style
	CommonOptionsParser op(clang_argc, clang_argv, ToolingCategory);
	ClangTool Tool(op.getCompilations(), op.getSourcePathList());

	// ClangTool::run accepts a FrontendActionFactory, which is then used to
	// create new objects implementing the FrontendAction interface. Here we
	// use the helper newFrontendActionFactory to create a default factory
	// that will return a new MyFrontendAction object every time.  To
	// further customize this, we could create our own factory class.
	// int ret = Tool.run(new MFAF(inst_files));
	int ret = Tool.run(newFrontendActionFactory<MyFrontendAction>());
	if (ret)
		errx(1, "Instrumentation failed");
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
	std::vector<std::string> source_files;
	const char *real_compiler_argv[argc + 1];

	for (int i = 0; i < argc; i++) {
		std::string arg(argv[i]);

		// copy argument verbatim for now, we'll replace later if needed
		real_compiler_argv[i] = argv[i];

		// Dirty hack to find source files
		if (ends_with(arg, ".cpp") || ends_with(arg, ".c")) {
			// Keep track of original source file names
			source_files.push_back(arg);
			std::string inst_src_path;

			// Append original directory or "." if relative path
			char *src_dir = dirname(arg.c_str());
			if (src_dir == NULL)
				err(1, "dirname");
			inst_src_path.append(src_dir);

			// Append instrumentation directory
			inst_src_path.append("/inst/");

			// Append original file name
			char *src_name = basename(arg.c_str());
			if (src_name == NULL)
				err(1, "basename");
			inst_src_path.append(src_name);

			// Compilation file will be instrumented source
			real_compiler_argv[i] = strdup(inst_src_path.c_str());
		}
	}
	// Very important that argv passed to execvp is NULL terminated
	real_compiler_argv[argc] = NULL;
	argv[argc] = NULL;

	// run native command if there's no source files to instrument
	if (source_files.size() == 0) {
#ifdef DEBUG
		warnx("no source files found on command line");
#endif
		clean_path();
		if (execvp(argv[0], argv))
			err(1, "execvp");
	}

	// run instrumentation on detected source files
	instrument(argc, argv, source_files);

#ifdef DEBUG
	std::cout << "Calling real compiler" << std::endl;
#endif
	clean_path();
	if (execvp(real_compiler_argv[0], (char *const *)real_compiler_argv))
		err(1, "execvp");
}
