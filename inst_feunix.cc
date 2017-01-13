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
#include "inst_feunix.h"

#include <sys/stat.h>		// stat
#include <sys/time.h>		// utimes
#include <sys/utsname.h>	// uname
#include <sys/wait.h>		// waitpid

#include <err.h>
#include <fstream>		// ifstream, ofstream
#include <unistd.h>		// execvp, fork, getpid, unlink


char
InstFrontendUnix::dir_sep()
{
	return '/';
}

char
InstFrontendUnix::path_sep()
{
	return ':';
}

std::string
InstFrontendUnix::lib_name()
{
	return "libcitrun.a";
}

void
InstFrontendUnix::log_os_str()
{
	struct utsname	 utsname;

	if (uname(&utsname) == -1)
		m_log << " (Unknown OS)";
	else
		m_log << " (" << utsname.sysname << "-" << utsname.release
			<< " " << utsname.machine << ")";
}

void
InstFrontendUnix::set_path(std::string const &new_path)
{
	if (setenv("PATH", new_path.c_str(), 1))
		err(1, "setenv");
}

//
// Copies one file to another preserving timestamps.
//
void
InstFrontendUnix::copy_file(std::string const &dst_fn, std::string const &src_fn)
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

bool
InstFrontendUnix::is_link(bool object_arg, bool compile_arg)
{
	if (!object_arg && !compile_arg && m_source_files.size() > 0)
		// Assume single line a.out compilation
		// $ gcc main.c
		return true;
	else if (object_arg && !compile_arg)
		// gcc -o main main.o fib.o while.o
		// gcc -o main main.c fib.c
		return true;

	return false;
}

//
// Execute the compiler by calling execvp(3) on the m_args vector.
//
void
InstFrontendUnix::exec_compiler()
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
InstFrontendUnix::fork_compiler()
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
