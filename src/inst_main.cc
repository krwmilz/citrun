/*
 * Copyright (c) 2016 Kyle Milz <kyle@0x30.net>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */
#include <sys/stat.h>		// stat
#include <sys/time.h>		// utimes
#include <sys/wait.h>		// waitpid

#include <clang/Tooling/CommonOptionsParser.h>
#include <clang/Tooling/Tooling.h>
#include <cstdio>		// tmpnam
#include <cstdlib>		// getenv
#include <cstring>		// strcmp
#include <err.h>
#include <fstream>
#include <iostream>
#include <sstream>
#include <string>
#include <unistd.h>		// execvp, fork, unlink

#include "inst_action.h"

#define STR_EXPAND(tok) #tok
#define STR(tok) STR_EXPAND(tok)

static llvm::cl::OptionCategory ToolingCategory("instrument options");

void
clean_path()
{
	char *path;

	if ((path = std::getenv("PATH")) == NULL)
		errx(1, "PATH must be set");

	// Filter CITRUN_PATH out of PATH
	std::stringstream path_ss(path);
	std::ostringstream new_path;
	std::string component;
	bool first_component = 1;
	bool found_citrun_path = 0;

	while (std::getline(path_ss, component, ':')) {
		if (component.compare(STR(CITRUN_PATH)) == 0) {
			found_citrun_path = 1;
			continue;
		}

		if (first_component == 0)
			new_path << ":";

		// It wasn't CITRUN_PATH, keep it
		new_path << component;
		first_component = 0;
	}

	if (!found_citrun_path)
		errx(1, "'%s' not in PATH", STR(CITRUN_PATH));

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
	// libcitrun.a uses pthread so we must link it here.
#ifndef __APPLE__
	// Except Mac OS, who always links this.
	args.push_back(const_cast<char *>("-pthread"));
#endif
	args.push_back(const_cast<char *>(STR(CITRUN_LIB)));
}

int
main(int argc, char *argv[])
{
	// We probably didn't call citrun-inst directly.
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
		if (std::strcmp(arg, "-E") == 0) {
			// Preprocessing argument found, exec native command
			if (execvp(argv[0], argv))
				err(1, "execvp");
		}
		else if (std::strcmp(arg, "-o") == 0)
			object_arg = true;
		else if (std::strcmp(arg, "-c") == 0)
			compile_arg = true;

		// Find source files
		if (ends_with(arg, ".c") || ends_with(arg, ".cc") ||
		    ends_with(arg, ".cpp") || ends_with(arg, ".cxx")) {

			// Keep track of original source file names
			source_files.push_back(arg);

			if (std::getenv("CITRUN_TESTING"))
				// Don't copy and restore original source files
				continue;

			char *dst_fn;
			if ((dst_fn = std::tmpnam(NULL)) == NULL)
				err(1, "tmpnam");

			copy_file(dst_fn, arg);
			temp_file_map[arg] = dst_fn;
		}
	}

	if (instrument(argc, argv, source_files)) {
		restore_original_src(temp_file_map);

		warnx("Instrumentation failed, compiling unmodified code.");
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

	// Instrumentation succeeded. Fork the native compiler.
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

	// Use the same return code as the native compiler.
	if (WIFEXITED(status))
		exit(WEXITSTATUS(status));
}
