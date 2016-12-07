//
// Copyright (c) 2016 Kyle Milz <kyle@0x30.net>
//
// Permission to use, copy, modify, and distribute this software for any
// purpose with or without fee is hereby granted, provided that the above
// copyright notice and this permission notice appear in all copies.
//
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
// WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
// ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
// WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
// ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
// OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
//
#include "inst_frontend.h"
#include "version.h"		// citrun_major, citrun_minor

#include <sys/stat.h>		// stat
#include <sys/time.h>		// utimes
#include <sys/utsname.h>	// uname
#include <sys/wait.h>		// waitpid

#include <clang/Frontend/TextDiagnosticBuffer.h>
#include <clang/Tooling/CommonOptionsParser.h>
#include <clang/Tooling/Tooling.h>
#include <cstdio>		// tmpnam
#include <cstring>		// strcmp
#include <err.h>
#include <fstream>		// ifstream, ofstream
#include <libgen.h>		// basename
#include <sstream>		// ostringstream
#include <unistd.h>		// execvp, fork, getpid, unlink


static llvm::cl::OptionCategory ToolingCategory("citrun-inst options");

InstrumentFrontend::InstrumentFrontend(int argc, char *argv[]) :
	m_args(argv, argv + argc),
	m_is_citruninst(false),
	m_start_time(std::chrono::high_resolution_clock::now())
{
	char		*base_name;
	struct utsname	 utsname;

	// Protect against argv[0] being an absolute path.
	if ((base_name = basename(m_args[0])) == NULL)
		err(1, "basename");

	// Switch tool mode if we're called as 'citrun-inst'.
	if (std::strcmp(base_name, "citrun-inst") == 0) {
		m_is_citruninst = true;
		// Enable logging to stdout.
		m_log.set_citruninst();
	}

	m_log << ">> citrun-inst v" << citrun_major << "." << citrun_minor;
	if (uname(&utsname) == -1)
		m_log << " Unknown OS" << std::endl;
	else
		m_log << " (" << utsname.sysname << "-" << utsname.release
			<< " " << utsname.machine << ")" << std::endl;

	m_log << "CITRUN_SHARE = '" << CITRUN_SHARE << "'" << std::endl;

	// Always re-search PATH for binary name (in non-citrun-inst case).
	m_log << "Switching argv[0] '" << m_args[0] << "' -> '" << base_name
		<< "'" << std::endl;
	m_args[0] = base_name;

	// Sometimes we're not called as citrun-inst so force that here.
	setprogname("citrun-inst");

	if (m_is_citruninst == false)
		clean_PATH();
}

//
// Tries to remove CITRUN_SHARE from PATH otherwise it exits easily.
//
void
InstrumentFrontend::clean_PATH()
{
	char *path;

	if ((path = std::getenv("PATH")) == NULL)
		errx(1, "Error: PATH is not set.");

	m_log << "PATH='" << path << "'" << std::endl;

	// Filter CITRUN_SHARE out of PATH
	std::stringstream path_ss(path);
	std::ostringstream new_path;
	std::string component;
	bool first_component = 1;
	bool found_citrun_path = 0;

	while (std::getline(path_ss, component, ':')) {
		if (component.compare(CITRUN_SHARE) == 0) {
			found_citrun_path = 1;
			continue;
		}

		if (first_component == 0)
			new_path << ":";

		// It wasn't CITRUN_SHARE, keep it
		new_path << component;
		first_component = 0;
	}

	if (!found_citrun_path)
		errx(1, "Error: CITRUN_SHARE not in PATH.");

	if (setenv("PATH", new_path.str().c_str(), 1))
		err(1, "setenv");
}


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
	if (stat(src_fn.c_str(), &sb) < 0)
		err(1, "stat");
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
	if (utimes(dst_fn.c_str(), st_tim) < 0)
		err(1, "utimes");
}

//
// Guess if the argument is a sourcefile. If it is stash a backup of the file
// and sync the timestamps.
//
void
InstrumentFrontend::save_if_srcfile(char *arg)
{
	if (!ends_with(arg, ".c") && !ends_with(arg, ".cc") &&
	    !ends_with(arg, ".cpp") && !ends_with(arg, ".cxx"))
		return;

	m_source_files.push_back(arg);
	m_log << "Found source file '" << arg << "'" << std::endl;

	if (m_is_citruninst)
		// In this mode the modified source file is written to a
		// completely different file.
		return;

	char *dst_fn;
	if ((dst_fn = std::tmpnam(NULL)) == NULL)
		err(1, "tmpnam");

	copy_file(dst_fn, arg);
	m_temp_file_map[arg] = dst_fn;
}

//
// Careful guessing if we're linking. Use an absolute path to libcitrun.a to
// avoid link failures.
//
void
InstrumentFrontend::if_link_add_runtime(bool object_arg, bool compile_arg)
{
	bool linking = false;

	if (!object_arg && !compile_arg && m_source_files.size() > 0)
		// Assume single line a.out compilation
		// $ gcc main.c
		linking = true;
	else if (object_arg && !compile_arg)
		// gcc -o main main.o fib.o while.o
		// gcc -o main main.c fib.c
		linking = true;

	if (!linking)
		return;

	m_log << "Link detected, adding '"<< CITRUN_SHARE "/libcitrun.a"
		<< "' to command line." << std::endl;
	m_args.push_back(const_cast<char *>(CITRUN_SHARE "/libcitrun.a"));
}

//
// Walks the entire command line taking action on important arguments.
//
void
InstrumentFrontend::process_cmdline()
{
	bool object_arg = false;
	bool compile_arg = false;

	//
	// Walk every argument one by one looking for preprocessor switches,
	// compile mode flags and source files.
	//
	for (auto &arg : m_args) {
		if (std::strcmp(arg, "-E") == 0 || std::strcmp(arg, "-MM") == 0) {
			// I don't know the repercussions of doing otherwise.
			m_log << "Preprocessor argument found" << std::endl;
			exec_compiler();
		}
		else if (std::strcmp(arg, "-o") == 0)
			object_arg = true;
		else if (std::strcmp(arg, "-c") == 0)
			compile_arg = true;

		save_if_srcfile(arg);
	}

	// If linking is detected append libcitrun.a to the command line.
	if_link_add_runtime(object_arg, compile_arg);

	m_log << "Modified command line is '";
	for (auto &arg : m_args)
		m_log << arg << " ";
	m_log << "'" << std::endl;

	if (m_source_files.size() != 0)
		return;

	m_log << "No source files found on command line." << std::endl;
	exec_compiler();
}

//
// Creates and executes InstrumentAction objects for detected source files.
//
void
InstrumentFrontend::instrument()
{
	//
	// Create a special command line for ClangTool that looks like:
	// clang++ src1.c src2.c -- clang++ -I. -Isrc -c src1.c src2.c
	//
	std::vector<const char *> clang_argv;

	clang_argv.push_back(m_args[0]);
	for (auto s : m_source_files)
		clang_argv.push_back(s.c_str());
	clang_argv.push_back("--");
	clang_argv.insert(clang_argv.end(), m_args.begin(), m_args.end());
#if defined(__OpenBSD__)
	clang_argv.push_back("-I/usr/local/lib/clang/3.9.0/include");
	m_log << "Added clangtool argument '" << clang_argv.back() << "'" << std::endl;
#elif defined(__APPLE__)
	clang_argv.push_back("-I/opt/local/libexec/llvm-3.8/lib/clang/3.8.1/include");
	m_log << "Added clangtool argument '" << clang_argv.back() << "'" << std::endl;
#endif

	int clang_argc = clang_argv.size();
	clang::tooling::CommonOptionsParser
		op(clang_argc, &clang_argv[0], ToolingCategory);
	clang::tooling::ClangTool
		Tool(op.getCompilations(), op.getSourcePathList());

	//
	// These diagnostics aren't too important because the input code could
	// be terrible.
	//
	clang::TextDiagnosticBuffer diag_buffer;
	Tool.setDiagnosticConsumer(&diag_buffer);

	std::unique_ptr<InstrumentActionFactory> f =
		llvm::make_unique<InstrumentActionFactory>(m_log, m_is_citruninst, m_source_files);

	// Run the ClangTool over an InstrumentActionFactory, instrumenting and
	// writing modified source code in place.
	int ret = Tool.run(f.get());
	m_log << "Rewriting " << (ret ? "failed." : "successful.") << std::endl;

	// All of the time until now is the overhead citrun-inst adds.
	std::chrono::high_resolution_clock::time_point now =
		std::chrono::high_resolution_clock::now();
	m_log << std::chrono::duration_cast<std::chrono::milliseconds>(now - m_start_time).count()
		<< " Milliseconds spent rewriting source." << std::endl;

	// This is as far as we go in citrun-inst mode.
	if (m_is_citruninst)
		exit(ret);

	// If rewriting failed original source files may be in an
	// inconsistent state.
	if (ret) {
		restore_original_src();
		exec_compiler();
	}
}

//
// Restore source files from stashed backups and sync timestamps.
//
void
InstrumentFrontend::restore_original_src()
{
	for (auto &tmp_file : m_temp_file_map) {
		m_log << "Restored '" << tmp_file.first << "'" << std::endl;

		copy_file(tmp_file.first, tmp_file.second);
		unlink(tmp_file.second.c_str());
	}
}

//
// Execute the compiler by calling execvp(3) on the m_args vector.
//
void
InstrumentFrontend::exec_compiler()
{
	if (m_is_citruninst) {
		m_log << "Running as citrun-inst, not calling exec()" << std::endl;
		exit(0);
	}

	// Null termination explicitly mentioned in execvp(3).
	m_args.push_back(NULL);
	if (execvp(m_args[0], &m_args[0]))
		err(1, "execvp");
}

//
// fork(2) then execute the compiler and wait for it to finish. Returns exit
// code of native compiler.
//
int
InstrumentFrontend::fork_compiler()
{
	pid_t child_pid;
	int status;
	int exit = -1;

	if ((child_pid = fork()) < 0)
		err(1, "fork");

	// If in child execute compiler.
	if (child_pid == 0)
		exec_compiler();

	m_log << "Forked compiler '" << m_args[0] << "' "
	       << "pid is '" << child_pid << "'" << std::endl;

	// Wait for the child to finish so we can get its exit code.
	if (waitpid(child_pid, &status, 0) < 0)
		err(1, "waitpid");

	// Decode the exit code from status.
	if (WIFEXITED(status))
		exit = WEXITSTATUS(status);

	m_log << "Rewritten source compile " << (exit ? "failed" : "successful")
		<< std::endl;

	// Return the exit code of the native compiler.
	return exit;
}
