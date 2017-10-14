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
#include <sys/mman.h>		/* mmap */
#include <sys/stat.h>		/* S_IRUSR, S_IWUSR, mkdir */

#include <assert.h>
#include <err.h>
#include <errno.h>		/* EEXIST */
#include <fcntl.h>		/* O_CREAT */
#include <limits.h>		/* PATH_MAX */
#include <stdlib.h>		/* get{env,progname} */
#include <string.h>		/* strl{cpy,cat} */
#include <unistd.h>		/* access, execlp, fork, lseek, get* */

#include "lib.h"		/* struct citrun_header */
#include "lib_os.h"

#define UNIX_PROCDIR	"/tmp/citrun"


/*
 * Implementation of lib_os.h interface for at least:
 * - OpenBSD
 * - Darwin
 * - Linux
 */

/*
 * Rounds up the second argument to a multiple of the system page size, which
 * makes working with mmap nicer.
 *
 * Get the current mapping length, extend it by truncation and then extend the
 * memory mapping.
 *
 * If this function fails the instrumented program will exit nonzero.
 */
void *
citrun_extend(int fd, size_t req_bytes)
{
	size_t	 aligned_bytes;
	off_t	 len;
	void	*mem;
	size_t	 page_mask;

	page_mask = getpagesize() - 1;
	aligned_bytes = (req_bytes + page_mask) & ~page_mask;

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

	return mem;
}

/*
 * If CITRUN_PROCDIR is not set UNIX_PROCDIR is used as a prefix. Attempt to
 * create the prefix but don't error if it already exists.
 *
 * Create a file name by concatenating the program name with a 10 character (man
 * page suggests this amount) random template and pass that to mkstemp(3).
 *
 * If this program fails the instrumented program will exit nonzero.
 */
int
citrun_open_fd()
{
	const char		*procdir;
	char			 procfile[PATH_MAX];
	int			 fd;

	if ((procdir = getenv("CITRUN_PROCDIR")) == NULL)
		procdir = UNIX_PROCDIR;

	if (mkdir(procdir, S_IRWXU) && errno != EEXIST)
		err(1, "mkdir '%s'", procdir);

	strlcpy(procfile, procdir, PATH_MAX);
	strlcat(procfile, "/", PATH_MAX);
	strlcat(procfile, getprogname(), PATH_MAX);
	strlcat(procfile, "_XXXXXXXXXX", PATH_MAX);

	if ((fd = mkstemp(procfile)) < 0)
		err(1, "mkstemp");

	return fd;
}

/*
 * Fills in the following fields:
 * - process id
 * - parent process id
 * - process group
 * - program name
 * - current working directory
 *
 * This function doesn't fail.
 */
void
citrun_os_info(struct citrun_header *h)
{
	h->pids[0] = getpid();
	h->pids[1] = getppid();
	h->pids[2] = getpgrp();

	strlcpy(h->progname, getprogname(), sizeof(h->progname));

	if (getcwd(h->cwd, sizeof(h->cwd)) == NULL)
		strncpy(h->cwd, "", sizeof(h->cwd));
}

/*
 * Checks for the global citrun_gl lock file in the directory either given by the
 * CITRUN_PROCDIR environment variable value or UNIX_PROCDIR if CITRUN_PROCDIR
 * doesn't exist.
 *
 * If no lock file exists a new process is forked that tries to exec 'citrun_gl'
 * which must be on the path.
 *
 * The instrumented program exits on failure and returns nothing on success.
 */
void
citrun_start_viewer()
{
	pid_t		 pid;
	const char	*procdir;
	char		 viewer_file[PATH_MAX];

	if ((procdir = getenv("CITRUN_PROCDIR")) == NULL)
		procdir = UNIX_PROCDIR;

	strlcpy(viewer_file, procdir, PATH_MAX);
	strlcat(viewer_file, "/", PATH_MAX);
	strlcat(viewer_file, "citrun_gl.lock", PATH_MAX);

	if (access(viewer_file, F_OK)) {
		/* If errno was ENOENT then fall through otherwise error. */
		if (errno != ENOENT)
			err(1, "access");
	} else
		/* File already exists, don't create a new viewer. */
		return;

	pid = fork();
	if (pid < 0)
		err(1, "fork");
	else if (pid > 0)
		/* In parent process. */
		return;

	/*
	 * Use a different name than the instrumented program this library is
	 * linked to for better diagnostics in error messages.
	 */
	setprogname("libcitrun");

	/* In child process, exec the viewer. */
	if (execlp("citrun_gl", "citrun_gl", NULL))
		err(1, "exec citrun_gl");
}
