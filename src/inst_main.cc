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

class CitrunInst {
public:
	CitrunInst(int, char *argv[]);
	int instrument();
	void patch_link_command();
	int fork_compiler();
	void restore_original_src();

private:
	std::vector<char *>	m_args;
	std::vector<std::string> m_source_files;
	std::map<std::string, std::string> m_temp_file_map;
	bool			m_object_arg;
	bool			m_compile_arg;
};

// Returns true if value ends with suffix, false otherwise.
static bool
ends_with(std::string const &value, std::string const &suffix)
{
	if (suffix.length() > value.length())
		return false;

	return std::equal(suffix.rbegin(), suffix.rend(), value.rbegin());
}

// Copies one file to another preserving timestamps.
static void
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

CitrunInst::CitrunInst(int argc, char *argv[]) :
	m_args(argv, argv + argc),
	m_object_arg(false),
	m_compile_arg(false)
{
	for (auto &arg : m_args) {
		if (std::strcmp(arg, "-E") == 0) {
			// Preprocessing argument found, exec native command
			m_args.push_back(NULL);
			if (execvp(m_args[0], &m_args[0]))
				err(1, "execvp");
		}
		else if (std::strcmp(arg, "-o") == 0)
			m_object_arg = true;
		else if (std::strcmp(arg, "-c") == 0)
			m_compile_arg = true;

		// Find source files
		if (ends_with(arg, ".c") || ends_with(arg, ".cc") ||
		    ends_with(arg, ".cpp") || ends_with(arg, ".cxx")) {

			// Keep track of original source file names
			m_source_files.push_back(arg);

			char *dst_fn;
			if ((dst_fn = std::tmpnam(NULL)) == NULL)
				err(1, "tmpnam");

			copy_file(dst_fn, arg);
			m_temp_file_map[arg] = dst_fn;
		}
	}
}

int
CitrunInst::instrument()
{
	std::vector<const char *> clang_argv;

	if (m_source_files.size() == 0)
		return 0;

	clang_argv.push_back(m_args[0]);
	for (auto s : m_source_files)
		clang_argv.push_back(s.c_str());

	clang_argv.push_back("--");

	// Append original command line verbatim
	clang_argv.insert(clang_argv.end(), m_args.begin(), m_args.end());

	// We should be able to get this programmatically, but I don't know how.
#if defined(__OpenBSD__)
	clang_argv.push_back("-I/usr/local/lib/clang/3.8.0/include");
#elif defined(__APPLE__)
	clang_argv.push_back("-I/opt/local/libexec/llvm-3.7/lib/clang/3.7/include");
#endif

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
	int ret = Tool.run(&(*clang::tooling::newFrontendActionFactory<InstrumentAction>()));

	if (ret == 0)
		return 0;

	// Instrumentation failed, try compiling with native compiler.
	restore_original_src();
	ret = fork_compiler();

	// Native compiler succeeded. This is bad.
	if (ret == 0) {
		warnx("citrun instrumentation failed, but the native "
			"compile succeeded!");
		return 0;
	}

	// Native compiler failed too. That's okay.
	return ret;
}

void
CitrunInst::restore_original_src()
{
	for (auto &tmp_file : m_temp_file_map) {
		copy_file(tmp_file.first, tmp_file.second);
		unlink(tmp_file.second.c_str());
	}
}

void
CitrunInst::patch_link_command()
{
	bool linking = false;

	if (!m_object_arg && !m_compile_arg && m_source_files.size() > 0)
		// Assume single line a.out compilation
		// $ gcc main.c
		linking = true;
	else if (m_object_arg && !m_compile_arg)
		// gcc -o main main.o fib.o while.o
		// gcc -o main main.c fib.c
		linking = true;

	if (!linking)
		return;

	// libcitrun.a uses pthread so we must link it here.
#ifndef __APPLE__
	// Except Mac OS, who always links this.
	m_args.push_back(const_cast<char *>("-pthread"));
#endif
	m_args.push_back(const_cast<char *>(STR(CITRUN_LIB)));
}

int
CitrunInst::fork_compiler()
{
	// m_args must be NULL terminated for exec*() functions.
	m_args.push_back(NULL);

	pid_t child_pid;
	if ((child_pid = fork()) < 0)
		err(1, "fork");

	if (child_pid == 0) {
		// In child
		if (execvp(m_args[0], &m_args[0]))
			err(1, "execvp");
	}

	int status;
	if (waitpid(child_pid, &status, 0) < 0)
		err(1, "waitpid");

	// Return the exit code of the native compiler.
	if (WIFEXITED(status))
		return WEXITSTATUS(status);

	return -1;
}

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
	if (setenv("PATH", new_path.str().c_str(), 1))
		err(1, "setenv");
}

int
main(int argc, char *argv[])
{
	// We probably didn't call citrun-inst directly.
	setprogname("citrun-inst");
	clean_path();

	CitrunInst main(argc, argv);

	if (main.instrument())
		return 1;

	main.patch_link_command();

	int ret = main.fork_compiler();
	main.restore_original_src();
	return ret;
}
