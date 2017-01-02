//
// if [[ ${1} = -* ]]; then
// echo "usage: citrun_wrap <build cmd>"
// exit 1
// fi
//
// export PATH="`citrun_inst --print-share`:$PATH"
// exec $@
//
#include <limits.h>		// PATH_MAX
#include <sstream>
#include <stdlib.h>		// setenv
#include <stdio.h>

#ifdef _WIN32
#include <windows.h>
#include <tchar.h>
#else // _WIN32
#include <unistd.h>		// execvp
#endif // _WIN32

static void
usage(void)
{
	fprintf(stderr, "usage: citrun_wrap <build_cmd>\n");
	exit(1);
}

#ifdef _WIN32
TCHAR *argv0;

static void
Err(int code, const char *fmt)
{
	char buf[256];

	FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM, NULL, GetLastError(),
		MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), buf, 256, NULL);

	fprintf(stderr, "%s: %s: %s\n", argv0, fmt, buf);
	ExitProcess(code);
}

int
_tmain(int argc, TCHAR *argv[])
{
	argv0 = argv[0];

	STARTUPINFO si;
	PROCESS_INFORMATION pi;

	ZeroMemory(&si, sizeof(si));
	si.cb = sizeof(si);
	ZeroMemory(&pi, sizeof(pi));

	if (argc < 2)
		usage();

	std::stringstream path;
	path << CITRUN_SHARE << ";";
	path << getenv("Path");

	if (SetEnvironmentVariable("PATH", path.str().c_str()) == 0)
		Err(1, "SetEnvironmentVariable");

	std::stringstream arg_string;
	arg_string << argv[1];
	for (unsigned int i = 2; i < argc; ++i)
		arg_string << " " << argv[i];

	if (!CreateProcess( NULL, (LPSTR) arg_string.str().c_str(), NULL, NULL, FALSE, 0, NULL, NULL, &si, &pi))
		Err(1, "CreateProcess");

	if (WaitForSingleObject(pi.hProcess, INFINITE) == WAIT_FAILED)
		Err(1, "WaitForSingleObject");

	DWORD exit_code;
	if (GetExitCodeProcess(pi.hProcess, &exit_code) == FALSE)
		Err(1, "GetExitCodeProcess");

	CloseHandle(pi.hProcess);
	CloseHandle(pi.hThread);

	return exit_code;
}
#else // _WIN32
int
main(int argc, char *argv[])
{
	char path[PATH_MAX];

	strlcpy(path, CITRUN_SHARE ":", PATH_MAX);
	strlcat(path, getenv("PATH"), PATH_MAX);

	if (setenv("PATH", path, 1))
		err(1, "setenv");

	argv[argc] = NULL;
	if (execvp(argv[1], argv + 1))
		err(1, "execv");
}
#endif // _WIN32
