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
#ifdef _WIN32
#include <direct.h>		/* getcwd */
#include <stdio.h>		/* stderr */
#include <windows.h>		/* HANDLE, MapViewOfFile, ... */
#include <io.h>
#define PATH_MAX 32000

#define DEFAULT_PROCDIR "C:\\CItRun"
static HANDLE			 h = INVALID_HANDLE_VALUE;
#else /* _WIN32 */
#include <sys/mman.h>		/* mmap */
#include <sys/stat.h>		/* S_IRUSR, S_IWUSR, mkdir */

#include <assert.h>
#include <err.h>
#include <errno.h>		/* EEXIST */
#include <fcntl.h>		/* O_CREAT */
#include <limits.h>		/* PATH_MAX */
#include <stdio.h>
#include <stdlib.h>		/* atexit, get{env,progname} */
#include <string.h>		/* str{l,n}cpy */
#include <unistd.h>		/* lseek get{cwd,pid,ppid,pgrp} */

#define DEFAULT_PROCDIR "/tmp/citrun"
static int			 fd;
#endif /* _WIN32 */

#include "lib.h"		/* citrun_*, struct citrun_{header,node} */


static struct citrun_header	*header;

#ifdef _WIN32
static void
Err(int code, const char *fmt)
{
	char buf[256];

	FormatMessageA(FORMAT_MESSAGE_FROM_SYSTEM, NULL, GetLastError(),
		MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), buf, 256, NULL);

	fprintf(stderr, "%s: %s", fmt, buf);
	exit(code);
}

HANDLE
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
#endif /* _WIN32 */

static size_t
align_bytes(size_t unaligned_bytes)
{
	size_t	 page_mask;

#ifdef _WIN32
	SYSTEM_INFO system_info;
	GetSystemInfo(&system_info);

	page_mask = system_info.dwAllocationGranularity - 1;
#else
	page_mask = getpagesize() - 1;
#endif // _WIN32
	return (unaligned_bytes + page_mask) & ~page_mask;
}

/*
 * Extends the file and memory mapping length of fd by a requested amount of
 * bytes (rounded up to the next page size).
 * Returns a pointer to the extended region on success, exits on failure.
 */
static void *
extend(size_t req_bytes)
{
	size_t	 aligned_bytes;
	size_t	 len;
	void	*mem;

	aligned_bytes = align_bytes(req_bytes);

#ifdef _WIN32
	HANDLE	 fm;

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
#else /* _WIN32 */
	/* Get current file length. */
	if ((len = lseek(fd, 0, SEEK_END)) < 0)
		err(1, "lseek");

	/* Increase file length, filling with zeros. */
	if (ftruncate(fd, len + aligned_bytes) < 0)
		err(1, "ftruncate from %lld to %llu", len, len + aligned_bytes);

	/* Increase memory mapping length. */
	mem = mmap(NULL, req_bytes, PROT_READ | PROT_WRITE, MAP_SHARED, fd, len);

	if (mem == MAP_FAILED)
		err(1, "mmap %zu bytes @ %llu", req_bytes, len);
#endif /* _WIN32 */

	return mem;
}

static void
get_prog_name(char *buf, size_t buf_size)
{
#ifdef _WIN32
	if (GetModuleFileName(NULL, buf, buf_size) == 0)
		Err(1, "GetModuleFileName");
#else
	strlcpy(buf, getprogname(), buf_size);
#endif
}

/*
 * Opens a file with a random suffix. Exits on error.
 */
static void
open_fd()
{
	char			*procdir;
	char			 procfile[PATH_MAX];

	if ((procdir = getenv("CITRUN_PROCDIR")) == NULL)
		procdir = DEFAULT_PROCDIR;

#ifdef _WIN32
	if (CreateDirectory(procdir, NULL) == 0 &&
	    GetLastError() != ERROR_ALREADY_EXISTS)
		Err(1, "CreateDirectory");

	strncpy(procfile, procdir, PATH_MAX);
	strncat(procfile, "\\", PATH_MAX);
	strncat(procfile, "program", PATH_MAX);
	strncat(procfile, "_XXXXXXXXXX", PATH_MAX);

	if ((h = mkstemp(procfile)) == INVALID_HANDLE_VALUE)
		Err(1, "mkstemp");
#else /* _WIN32 */
	if (mkdir(procdir, S_IRWXU) && errno != EEXIST)
		err(1, "mkdir '%s'", procdir);

	strlcpy(procfile, procdir, PATH_MAX);
	strlcat(procfile, "/", PATH_MAX);
	strlcat(procfile, getprogname(), PATH_MAX);
	strlcat(procfile, "_XXXXXXXXXX", PATH_MAX);

	if ((fd = mkstemp(procfile)) < 0)
		err(1, "mkstemp");
#endif /* _WIN32 */
}

/*
 * Called by atexit(3), which doesn't always get called (this is unreliable).
 */
static void
set_exited(void)
{
	header->exited = 1;
}

/*
 * Extends the memory mapping and puts a struct citrun_header on top of it.
 */
static void
add_header()
{
	header = extend(sizeof(struct citrun_header));

	/* Must be exactly 4 bytes. */
	strncpy(header->magic, "ctrn", sizeof(header->magic));

	header->major = citrun_major;
	header->minor = citrun_minor;
	header->pids[0] = getpid();
#ifndef _WIN32
	header->pids[1] = getppid();
	header->pids[2] = getpgrp();
#endif /* ! _WIN32 */

	get_prog_name(header->progname, sizeof(header->progname));

	if (getcwd(header->cwd, sizeof(header->cwd)) == NULL)
		strncpy(header->cwd, "", 3);

	atexit(set_exited);
}

/*
 * Public Interface.
 *
 * Copies n into the shared memory file and then points n->data to a region of
 * memory located right after n that's at least 8 * n->size large.
 * Exits on failure.
 */
void
citrun_node_add(unsigned int major, unsigned int minor, struct citrun_node *n)
{
	size_t			 sz;
	struct citrun_node	*new;

	/* Binary compatibility between versions not guaranteed. */
	if (major != citrun_major || minor != citrun_minor) {
		fprintf(stderr, "libcitrun %i.%i: incompatible version %i.%i.\n"
			"Try cleaning and rebuilding your project.\n",
			citrun_major, citrun_minor, major, minor);
		exit(1);
	}

#ifdef _WIN32
	if (h == INVALID_HANDLE_VALUE) {
#else
	if (fd == 0) {
#endif /* _WIN32 */
		open_fd();
		add_header();
	}

	/* Allocate enough room for node and live execution buffers. */
	sz = sizeof(struct citrun_node);
	sz += n->size * sizeof(unsigned long long);
	new = extend(sz);

	/* Increment accumulation fields in header. */
	header->units++;
	header->loc += n->size;

	/* Copy these fields from incoming node verbatim. */
	new->size = n->size;
	strncpy(new->comp_file_path, n->comp_file_path, 1024);
	strncpy(new->abs_file_path,  n->abs_file_path, 1024);
	new->comp_file_path[1023] = new->abs_file_path[1023] = '\0';

	/* Set incoming nodes data pointer to allocated space after struct. */
	n->data = (unsigned long long *)(new + 1);
}
