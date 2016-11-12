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
#include <stddef.h>		/* offsetof */
#include <stdlib.h>		/* get{env,progname} */
#include <string.h>		/* strnlen */
#include <unistd.h>		/* get{cwd,pid,ppid,pgrp} */

#include "rt.h"			/* struct citrun_{header,node} */
#include "version.h"

#define SHM_PATH "/tmp/citrun.shared"

static int init = 0;
static int shm_fd = 0;
static size_t shm_len = 0;

/*
 * Extends the memory mapping of shm_fd some number of bytes rounded up to the
 * next page size.
 * Exits on error, returns a pointer to the beginning of the extended memory
 * region on success.
 */
static uint8_t *
shm_extend(int bytes)
{
	uint8_t		*shm;
	int		 page_size = getpagesize();
	int		 page_mask = page_size - 1;
	int		 aligned_bytes;

	aligned_bytes = ((bytes) + page_mask) & ~page_mask;

	/* Increase the length of the file descriptor. */
	if (ftruncate(shm_fd, shm_len + aligned_bytes) < 0)
		err(1, "ftruncate from %zu to %zu", shm_len, shm_len + aligned_bytes);

	/* Increase the size of the memory mapping. */
	shm = mmap(NULL, bytes, PROT_READ | PROT_WRITE, MAP_SHARED,
		shm_fd, shm_len);

	if (shm == MAP_FAILED)
		err(1, "mmap %i bytes @ %zu", bytes, shm_len);

	/* Increase internal length field. */
	shm_len += aligned_bytes;
	return shm;
}

/*
 * Add a header region to a newly created shared memory file.  Header size is
 * rounded up to next page size multiple. Exits on error.
 */
static void
shm_add_header()
{
	uint8_t		*shm;

	struct citrun_header header = {
		"citrun",
		citrun_major,
		citrun_minor
	};

	header.pids[0] = getpid();
	header.pids[1] = getppid();
	header.pids[2] = getpgrp();

	strlcpy(header.progname, getprogname(), PATH_MAX);

	if (getcwd(header.cwd, PATH_MAX) == NULL)
		err(1, "getcwd");

	shm = shm_extend(sizeof(struct citrun_header));
	memcpy(shm, &header, sizeof(struct citrun_header));
}

/*
 * Creates a new shared memory file and header.
 * Then citrun_node's are added as their constructors are executed.
 * This function should only be called once per process. Exits on failure.
 */
static void
shm_create()
{
	char	 memfile_path[23];
	char	*template = "/tmp/citrun/XXXXXXXXXX";
	char	*process_dir  = "/tmp/citrun";

	assert(shm_fd == 0);
	assert(shm_len == 0);

	if (getenv("CITRUN_TOOLS") != NULL) {
		if ((shm_fd = open("procfile.shm", O_RDWR | O_CREAT,
		    S_IRUSR | S_IWUSR)) == -1)
			err(1, "open");
	} else {
		/* Existing directory is OK. */
		if (mkdir(process_dir, S_IRWXU) && errno != EEXIST)
			err(1, "mkdir '%s'", process_dir);

		strlcpy(memfile_path, template, sizeof(memfile_path));

		if ((shm_fd = mkstemp(memfile_path)) == -1)
			err(1, "mkstemp");
	}

	init++;
	shm_add_header();
}

/*
 * Public interface, called by instrumented translation units.
 *
 * Copies the passed in citrun_node into the shared memory file.
 * Care is taken to allocate enough memory for the execution buffers which are
 * 8 * L bytes (L = total number of source code lines).
 * Node size is rounded up to the next page size multiple.
 * Exits on failure.
 */
void
citrun_node_add(uint8_t node_major, uint8_t node_minor, struct citrun_node *n)
{
	uint8_t		*shm;
	size_t		 sz = 0;

	/* Binary compatibility between versions not guaranteed.  */
	if (node_major != citrun_major || node_minor != citrun_minor)
		errx(1, "libcitrun-%i.%i: incompatible version %i.%i, "
			"try cleaning and rebuilding your project",
			citrun_major, citrun_minor, node_major, node_minor);

	if (!init)
		shm_create();

	sz += sizeof(struct citrun_node);
	sz += n->size * sizeof(uint64_t);

	shm = shm_extend(sz);

	/* n->data = (uint64_t *)(shm + offsetof(struct citrun_node,data)); */
	n->data = 0xF0F0F0F0F0F0F0F0;
	memcpy(shm, n, sizeof(struct citrun_node));
	n->data = (uint64_t *)(shm + sizeof(struct citrun_node));
}
