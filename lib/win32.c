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
#include <direct.h>		/* getcwd */
#include <stdio.h>		/* stderr */
#include <windows.h>		/* HANDLE, MapViewOfFile, ... */
#include <io.h>
#define PATH_MAX 32000

#include "citrun.h"		/* struct citrun_header */
#include "os.h"


static HANDLE			 h = INVALID_HANDLE_VALUE;

static void
Err(int code, const char *fmt)
{
	char buf[256];

	FormatMessageA(FORMAT_MESSAGE_FROM_SYSTEM, NULL, GetLastError(),
		MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), buf, 256, NULL);

	fprintf(stderr, "%s: %s", fmt, buf);
	exit(code);
}

static HANDLE
mkstemp(char *template)
{
	int i;
	unsigned int r;

	char chars[] = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";

	for (i = strlen(template) - 1; i > 0; --i) {
		if (template[i] != 'X')
			break;

		if (rand_s(&r)) {
			fprintf(stderr, "rand failed: %s\n", strerror(errno));
			exit(1);
		}

		template[i] = chars[r % (sizeof(chars) - 1)];
	}

	return CreateFile(
		template,
		GENERIC_READ | GENERIC_WRITE,
		0,
		NULL,
		CREATE_NEW,
		0,
		NULL
	);
}

/*
 * Extends the file and memory mapping length of fd by a requested amount of
 * bytes (rounded up to the next page size).
 * Returns a pointer to the extended region on success, exits on failure.
 */
void *
citrun_extend(size_t req_bytes)
{
	size_t	 aligned_bytes;
	size_t	 len;
	HANDLE	 fm;
	void	*mem;
	size_t	 page_mask;

	SYSTEM_INFO system_info;
	GetSystemInfo(&system_info);

	page_mask = system_info.dwAllocationGranularity - 1;
	aligned_bytes = (req_bytes + page_mask) & ~page_mask;

	/* Get current file length. */
	if ((len = GetFileSize(h, NULL)) == INVALID_FILE_SIZE)
		Err(1, "GetFileSize");

	/* Increase file pointer to new length. */
	if (SetFilePointer(h, len + aligned_bytes, NULL, FILE_BEGIN)
	    == INVALID_SET_FILE_POINTER)
		Err(1, "SetFilePointer");

	/* Set new length. */
	if (SetEndOfFile(h) == 0)
		Err(1, "SetEndOfFile");

	/* Create a new mapping that's used temporarily. */
	if ((fm = CreateFileMapping(h, NULL, PAGE_READWRITE, 0, 0, NULL)) == NULL)
		Err(1, "CreateFileMapping");

	/* Create a new memory mapping for the newly extended space. */
	if ((mem = MapViewOfFile(fm, FILE_MAP_READ | FILE_MAP_WRITE, 0, len, req_bytes)) == NULL)
		Err(1, "MapViewOfFile");

	CloseHandle(fm);
	return mem;
}

/*
 * Opens a file with a random suffix. Exits on error.
 */
void
citrun_open_fd()
{
	char			*procdir;
	char			 procfile[PATH_MAX];

	if ((procdir = getenv("CITRUN_PROCDIR")) == NULL)
		procdir = "C:\\CItRun";

	if (CreateDirectory(procdir, NULL) == 0 &&
	    GetLastError() != ERROR_ALREADY_EXISTS)
		Err(1, "CreateDirectory");

	strncpy(procfile, procdir, PATH_MAX);
	strncat(procfile, "\\", PATH_MAX);
	strncat(procfile, "program", PATH_MAX);
	strncat(procfile, "_XXXXXXXXXX", PATH_MAX);

	if ((h = mkstemp(procfile)) == INVALID_HANDLE_VALUE)
		Err(1, "mkstemp");
}

void
citrun_os_info(struct citrun_header *h)
{
	h->pids[0] = getpid();

	if (GetModuleFileName(NULL, h->progname, sizeof(h->progname)) == 0)
		Err(1, "GetModuleFileName");

	if (getcwd(h->cwd, sizeof(h->cwd)) == NULL)
		strncpy(h->cwd, "", sizeof(h->cwd));
}
