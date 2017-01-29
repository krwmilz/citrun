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
#include "inst_fewin32.h"

#include <windows.h>		// CreateProcess
#include <Shlwapi.h>		// PathFindOnPath

#include <array>
#include <cstdio>		// tmpnam
#include <cstring>		// strcmp
#include <fstream>		// ifstream, ofstream
#include <iostream>		// cerr
#include <sstream>		// ostringstream

#define PATH_SEP ';'


static void
Err(int code, const char *fmt)
{
	char buf[256];

	FormatMessageA(FORMAT_MESSAGE_FROM_SYSTEM, NULL, GetLastError(),
		MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), buf, 256, NULL);

	std::cerr << fmt << ": " << buf << std::endl;
	ExitProcess(code);
}

char
InstFrontendWin32::dir_sep()
{
	return '\\';
}

char
InstFrontendWin32::path_sep()
{
	return ';';
}

std::string
InstFrontendWin32::lib_name()
{
	return "libcitrun.lib";
}

void
InstFrontendWin32::log_os_str()
{
	m_log << " (Windows x86)";
}

void
InstFrontendWin32::set_path(std::string const & new_path)
{
	if (SetEnvironmentVariableA("Path", new_path.c_str()) == 0)
		Err(1, "SetEnvironmentVariableA");
}

void
InstFrontendWin32::copy_file(std::string const &dst_fn, std::string const &src_fn)
{
	// TODO: Timestamp saving.

	std::ifstream src(src_fn, std::ios::binary);
	std::ofstream dst(dst_fn, std::ios::binary);

	dst << src.rdbuf();

	src.close();
	dst.close();
}

bool
InstFrontendWin32::is_link(bool object_arg, bool compile_arg)
{
	if (std::strcmp(m_args[0], "link") == 0)
		// If we're called as link.exe we're linking for sure.
		return true;
	if (!compile_arg && m_source_files.size() > 0)
		// cl.exe main.c
		return true;

	return false;
}

//
// On Windows the best exec alternative is to CreateProcess, wait for it to
// finish and exit with its exit code. Windows has execvp, but it looks to
// CreateProcess and then itself exit, leading to race conditions.
//
void
InstFrontendWin32::exec_compiler()
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
InstFrontendWin32::fork_compiler()
{
	DWORD exit = -1;
	STARTUPINFOA si;
	PROCESS_INFORMATION pi;

	ZeroMemory(&si, sizeof(si));
	si.cb = sizeof(si);
	ZeroMemory(&pi, sizeof(pi));

	char real_cc[MAX_PATH];
	std::strcpy(real_cc, m_args[0]);

	std::array<std::string, 2> exts = {{ ".exe", ".EXE" }};
	if (std::find_if(exts.begin(), exts.end(), ends_with(real_cc)) == exts.end())
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
