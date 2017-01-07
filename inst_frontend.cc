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
#include "lib.h"		// citrun_major, citrun_minor

#include <sys/stat.h>		// stat

#include <clang/Frontend/TextDiagnosticBuffer.h>
#include <clang/Tooling/CommonOptionsParser.h>
#include <clang/Tooling/Tooling.h>
#include <cstdio>		// tmpnam
#include <cstring>		// strcmp
#include <fstream>		// ifstream, ofstream
#include <iostream>		// cerr
#include <sstream>		// ostringstream

#ifdef _WIN32
#include <windows.h>		// CreateProcess
#include <Shlwapi.h>		// PathFindOnPath

#define PATH_SEP ';'
#else // _WIN32
#include <sys/time.h>		// utimes
#include <sys/utsname.h>	// uname
#include <sys/wait.h>		// waitpid

#include <err.h>
#include <unistd.h>		// execvp, fork, getpid, unlink

#define PATH_SEP ':'
#endif // _WIN32

#define xstr(x) make_str(x)
#define make_str(x) #x


static llvm::cl::OptionCategory ToolingCategory("citrun_inst options");

#ifdef _WIN32
static void
Err(int code, const char *fmt)
{
	char buf[256];

	FormatMessageA(FORMAT_MESSAGE_FROM_SYSTEM, NULL, GetLastError(),
		MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), buf, 256, NULL);

	std::cerr << fmt << ": " << buf << std::endl;
	ExitProcess(code);
}
#endif // _WIN32

InstFrontend::InstFrontend(int argc, char *argv[], bool is_citrun_inst) :
	m_args(argv, argv + argc),
	m_log(is_citrun_inst),
	m_is_citruninst(is_citrun_inst),
	m_start_time(std::chrono::high_resolution_clock::now())
{
	log_identity();

	const char *citrun_path = std::getenv("CITRUN_PATH");

	m_compilers_path = citrun_path ? citrun_path : "" ;
	m_compilers_path.append("compilers");

	m_lib_path = citrun_path ? citrun_path : "" ;
#ifdef _WIN32
	m_lib_path.append("libcitrun.lib");
#else
	m_lib_path_append("libcitrun.a");
#endif // _WIN32

	m_log << "CITRUN_COMPILERS = '" << m_compilers_path << "'" << std::endl;

#ifndef _WIN32
	// Sometimes we're not called as citrun_inst so force that here.
	setprogname("citrun_inst");
#endif // _WIN32

	if (m_is_citruninst == false)
		clean_PATH();
}

void
InstFrontend::log_identity()
{
	m_log << ">> citrun_inst v" << citrun_major << "." << citrun_minor;
#ifdef _WIN32
	m_log << " (Windows x86)";
#else // _WIN32
	struct utsname	 utsname;

	if (uname(&utsname) == -1)
		m_log << " (Unknown OS)";
	else
		m_log << " (" << utsname.sysname << "-" << utsname.release
			<< " " << utsname.machine << ")";
#endif // _WIN32
	m_log << " called as " << m_args[0] << std::endl;
}

//
// Tries to remove m_compilers_path from PATH otherwise it exits easily.
//
void
InstFrontend::clean_PATH()
{
	char *path;

	if ((path = std::getenv("PATH")) == NULL) {
		std::cerr << "Error: PATH is not set." << std::endl;
		m_log <<     "Error: PATH is not set." << std::endl;
		exit(1);
	}

	m_log << "PATH='" << path << "'" << std::endl;

	// Filter m_compilers_path out of PATH
	std::stringstream path_ss(path);
	std::ostringstream new_path;
	std::string component;
	bool first_component = 1;
	bool found_citrun_path = 0;

	while (std::getline(path_ss, component, PATH_SEP)) {
		if (component == m_compilers_path) {
			found_citrun_path = 1;
			continue;
		}

		if (first_component == 0)
			new_path << PATH_SEP;

		// It wasn't m_compilers_path, keep it
		new_path << component;
		first_component = 0;
	}

	if (!found_citrun_path) {
		std::cerr << "Error: " << m_compilers_path << " not in PATH." << std::endl;
		m_log <<     "Error: " << m_compilers_path << " not in PATH." << std::endl;
		exit(1);
	}

#ifdef _WIN32
	if (SetEnvironmentVariableA("Path", new_path.str().c_str()) == 0)
		Err(1, "SetEnvironmentVariableA");
#else // _WIN32
	if (setenv("PATH", new_path.str().c_str(), 1))
		err(1, "setenv");
#endif // _WIN32
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
InstFrontend::save_if_srcfile(char *arg)
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
// Careful guessing if we're linking. Use an absolute path to libcitrun to
// avoid link failures.
//
void
InstFrontend::if_link_add_runtime(bool object_arg, bool compile_arg)
{
#ifdef _WIN32
	bool linking = false;

	if (std::strcmp(m_args[0], "link") == 0)
		// If we're called as link.exe we're linking for sure.
		linking = true;
	if (!compile_arg && m_source_files.size() > 0)
		// cl.exe main.c
		linking = true;

	if (!linking)
		return;
#else // _WIN32
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
#endif // _WIN32

	m_log << "Link detected, adding '"<< m_lib_path
		<< "' to command line." << std::endl;
	m_args.push_back(const_cast<char *>(m_lib_path.c_str()));
}

//
// Walks the entire command line taking action on important arguments.
//
void
InstFrontend::process_cmdline()
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
			m_log << "Preprocessor argument " << arg << " found"
				<< std::endl;
			exec_compiler();
		}
		else if (std::strcmp(arg, "-o") == 0)
			object_arg = true;
		else if (std::strcmp(arg, "-c") == 0)
			compile_arg = true;
#ifdef _WIN32
		else if (std::strcmp(arg, "/c") == 0)
			compile_arg = true;
#endif // _WIN32

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
InstFrontend::instrument()
{
	//
	// Create a special command line for ClangTool that looks like:
	// clang++ src1.c src2.c -- clang++ -I. -Isrc -c src1.c src2.c
	//
	std::vector<const char *> clang_argv;

	clang_argv.push_back(m_args[0]);
	for (auto &s : m_source_files)
		clang_argv.push_back(s.c_str());
	clang_argv.push_back("--");
	clang_argv.insert(clang_argv.end(), m_args.begin(), m_args.end());
#if defined(__OpenBSD__)
	clang_argv.push_back("-I/usr/local/lib/clang/3.8.0/include");
	m_log << "Added clangtool argument '" << clang_argv.back() << "'" << std::endl;
#elif defined(__APPLE__)
	clang_argv.push_back("-I/opt/local/libexec/llvm-3.8/lib/clang/3.8.1/include");
	m_log << "Added clangtool argument '" << clang_argv.back() << "'" << std::endl;
#elif defined(WIN32)
	clang_argv.push_back("-IC:\\Clang\\lib\\clang\\3.9.1\\include");
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

	// All of the time until now is the overhead citrun_inst adds.
	std::chrono::high_resolution_clock::time_point now =
		std::chrono::high_resolution_clock::now();
	m_log << std::chrono::duration_cast<std::chrono::milliseconds>(now - m_start_time).count()
		<< " Milliseconds spent rewriting source." << std::endl;

	// This is as far as we go in citrun_inst mode.
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
InstFrontend::restore_original_src()
{
	for (auto &tmp_file : m_temp_file_map) {
		m_log << "Restored '" << tmp_file.first << "'" << std::endl;

		copy_file(tmp_file.first, tmp_file.second);
		unlink(tmp_file.second.c_str());
	}
}

void
InstFrontend::compile_instrumented()
{
	int ret;

	ret = fork_compiler();
	m_log << "Rewritten source compile " << (ret ? "failed" : "successful")
		<< std::endl;

	restore_original_src();

	if (ret)
		// Rewritten compile failed. Run again without modified src.
		exec_compiler();
}

#ifdef _WIN32
//
// On Windows the best exec alternative is to CreateProcess, wait for it to
// finish and exit with its exit code. Windows has execvp, but it looks to
// CreateProcess and then itself exit, leading to race conditions.
//
void
InstFrontend::exec_compiler()
{
	if (m_is_citruninst) {
		m_log << "Running as citrun_inst, not calling exec()" << std::endl;
		exit(0);
	}

	exit(fork_compiler());
}

//
// On Windows this is a straighforward conversion. We do our own PATH lookup
// because the default one CreateProcess does will find our cl.exe again
// instead of searching the PATH for a new one.
//
int
InstFrontend::fork_compiler()
{
	DWORD exit = -1;
	STARTUPINFOA si;
	PROCESS_INFORMATION pi;

	ZeroMemory(&si, sizeof(si));
	si.cb = sizeof(si);
	ZeroMemory(&pi, sizeof(pi));

	char real_cc[MAX_PATH];
	std::strcpy(real_cc, m_args[0]);

	if (!ends_with(real_cc, ".exe") && !ends_with(real_cc, ".EXE"))
		std::strcat(real_cc, ".exe");

	if (PathFindOnPathA(real_cc, NULL) == FALSE)
		m_log << "PathFindOnPathA failed for " << real_cc << std::endl;

	std::stringstream argv;
	for (unsigned int i = 1; i < m_args.size(); ++i)
		argv << " " << m_args[i];

	if (!CreateProcessA(real_cc,
			(LPSTR) argv.str().c_str(),
			NULL,
			NULL,
			FALSE,
			0,
			NULL,
			NULL,
			&si,
			&pi))
		Err(1, "CreateProcess");

	m_log << "Forked compiler '" << real_cc << "' "
	       << "pid is '" << pi.dwProcessId << "'" << std::endl;

	if (WaitForSingleObject(pi.hProcess, INFINITE) == WAIT_FAILED)
		Err(1, "WaitForSingleObject");

	if (GetExitCodeProcess(pi.hProcess, &exit) == FALSE)
		Err(1, "GetExitCodeProcess");

	CloseHandle(pi.hProcess);
	CloseHandle(pi.hThread);

	return exit;
}
#else // _WIN32
//
// Execute the compiler by calling execvp(3) on the m_args vector.
//
void
InstFrontend::exec_compiler()
{
	if (m_is_citruninst) {
		m_log << "Running as citrun_inst, not calling exec()" << std::endl;
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
InstFrontend::fork_compiler()
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

	// Return the exit code of the native compiler.
	return exit;
}
#endif // _WIN32
