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
#include <string.h>		/* str{l,n}cpy */
#include <unistd.h>		/* lseek get{cwd,pid,ppid,pgrp} */

#include "rt.h"			/* citrun_*, struct citrun_{header,node} */


static int			 shm_fd = 0;
static struct citrun_header	*shm_header;

/*
 * Extends the file and memory mapping length of shm_fd by a requested amount of
 * bytes (rounded up to the next page size).
 * Returns a pointer to the extended region on success, exits on failure.
 */
static void *
shm_extend(size_t requested_bytes)
{
	size_t	 aligned_bytes, page_mask;
	off_t	 shm_len;
	void	*shm;

	page_mask = getpagesize() - 1;
	aligned_bytes = (requested_bytes + page_mask) & ~page_mask;

	/* Get current file length. */
	if ((shm_len = lseek(shm_fd, 0, SEEK_END)) < 0)
		err(1, "lseek");

	/* Increase file length. */
	if (ftruncate(shm_fd, shm_len + aligned_bytes) < 0)
		err(1, "ftruncate from %lld to %llu", shm_len, shm_len + aligned_bytes);

	/* Increase memory mapping length. */
	shm = mmap(NULL, requested_bytes, PROT_READ | PROT_WRITE, MAP_SHARED,
		shm_fd, shm_len);

	if (shm == MAP_FAILED)
		err(1, "mmap %zu bytes @ %llu", requested_bytes, shm_len);

	return shm;
}

/*
 * Creates a new shared memory file with a header. Exits on error.
 */
static void
shm_create()
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

	if ((shm_fd = mkstemp(procfile)) < 0)
		err(1, "mkstemp");

	/* Add header. */
	assert(sizeof(struct citrun_header) < getpagesize());
	shm_header = shm_extend(sizeof(struct citrun_header));

	/* Purposefully not null terminated. */
	strncpy(shm_header->magic, "ctrn", sizeof(shm_header->magic));

	shm_header->major = citrun_major;
	shm_header->minor = citrun_minor;
	shm_header->pids[0] = getpid();
	shm_header->pids[1] = getppid();
	shm_header->pids[2] = getpgrp();
	shm_header->units = 0;
	shm_header->loc = 0;

	/* getprogname() should never fail. */
	strlcpy(shm_header->progname, getprogname(), sizeof(shm_header->progname));

	if (getcwd(shm_header->cwd, sizeof(shm_header->cwd)) == NULL)
		err(1, "getcwd");
}

/*
 * Public interface: Called by all instrumented translation units.
 * Copies n into the shared memory file and then points n->data to a region of
 * memory located right after n that's at least 8 * n->size large.
 * Exits on failure.
 */
void
citrun_node_add(unsigned int major, unsigned int minor, struct citrun_node *n)
{
	size_t			 sz;
	struct citrun_node	*shm_node;

	/* Binary compatibility between versions not guaranteed. */
	if (major != citrun_major || minor != citrun_minor)
		errx(1, "libcitrun-%i.%i: incompatible version %i.%i, "
			"try cleaning and rebuilding your project",
			citrun_major, citrun_minor, major, minor);

	if (shm_fd == 0)
		shm_create();

	sz = sizeof(struct citrun_node);
	sz += n->size * sizeof(unsigned long long);

	shm_header->units++;
	shm_header->loc += n->size;

	shm_node = shm_extend(sz);

	shm_node->size = n->size;
	strlcpy(shm_node->comp_file_path, n->comp_file_path, 1024);
	strlcpy(shm_node->abs_file_path, n->abs_file_path, 1024);

	n->data = (unsigned long long *)(shm_node + 1);
}
