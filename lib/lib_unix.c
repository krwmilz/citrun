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
#include <unistd.h>		/* lseek get{cwd,pid,ppid,pgrp} */

#include "libP.h"

static int			 fd;

/*
 * Extends the file and memory mapping length of fd by a requested amount of
 * bytes (rounded up to the next page size).
 * Returns a pointer to the extended region on success, exits on failure.
 */
void *
citrun_extend(size_t req_bytes)
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
 * Opens a file with a random suffix. Exits on error.
 */
void
citrun_open_fd()
{
	const char		*procdir;
	char			 procfile[PATH_MAX];

	if ((procdir = getenv("CITRUN_PROCDIR")) == NULL)
		procdir = "/tmp/citrun";

	if (mkdir(procdir, S_IRWXU) && errno != EEXIST)
		err(1, "mkdir '%s'", procdir);

	strlcpy(procfile, procdir, PATH_MAX);
	strlcat(procfile, "/", PATH_MAX);
	strlcat(procfile, getprogname(), PATH_MAX);
	strlcat(procfile, "_XXXXXXXXXX", PATH_MAX);

	if ((fd = mkstemp(procfile)) < 0)
		err(1, "mkstemp");
}

/*
 * Fills in a few operating system specific fields in struct citrun_header.
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
