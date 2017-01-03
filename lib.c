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
#include <stdlib.h>		/* atexit, get{env,progname} */
#include <string.h>		/* str{l,n}cpy */
#include <unistd.h>		/* lseek get{cwd,pid,ppid,pgrp} */

#include "lib.h"		/* citrun_*, struct citrun_{header,node} */


static int			 fd;
static struct citrun_header	*header;

/*
 * Extends the file and memory mapping length of fd by a requested amount of
 * bytes (rounded up to the next page size).
 * Returns a pointer to the extended region on success, exits on failure.
 */
static void *
extend(size_t req_bytes)
{
	size_t	 aligned_bytes, page_mask;
	off_t	 len;
	void	*mem;

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
static void
open_fd()
{
	char			*procdir;
	char			 procfile[PATH_MAX];

	/* User of this env var must give trailing slash */
	if ((procdir = getenv("CITRUN_PROCDIR")) == NULL)
		procdir = "/tmp/citrun/";

	if (mkdir(procdir, S_IRWXU) && errno != EEXIST)
		err(1, "mkdir '%s'", procdir);

	strlcpy(procfile, procdir, PATH_MAX);
	strlcat(procfile, getprogname(), PATH_MAX);
	strlcat(procfile, "_XXXXXXXXXX", PATH_MAX);

	if ((fd = mkstemp(procfile)) < 0)
		err(1, "mkstemp");
}

/*
 * Called by atexit(3), which doesn't always get called (this is unreliable).
 */
static void
set_exited()
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
	header->pids[1] = getppid();
	header->pids[2] = getpgrp();

	/* getprogname() should never fail. */
	strlcpy(header->progname, getprogname(), sizeof(header->progname));

	if (getcwd(header->cwd, sizeof(header->cwd)) == NULL)
		strlcpy(header->cwd, "<none>", 7);

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
	if (major != citrun_major || minor != citrun_minor)
		errx(1, "libcitrun %i.%i: incompatible version %i.%i, "
			"try cleaning and rebuilding your project",
			citrun_major, citrun_minor, major, minor);

	if (fd == 0) {
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
	strlcpy(new->comp_file_path, n->comp_file_path, 1024);
	strlcpy(new->abs_file_path,  n->abs_file_path, 1024);

	/* Set incoming nodes data pointer to allocated space after struct. */
	n->data = (unsigned long long *)(new + 1);
}
