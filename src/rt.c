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
#include <string.h>		/* strnlen */
#include <unistd.h>		/* get{cwd,pid,ppid,pgrp} */

#include "rt.h"
#include "version.h"

#define SHM_PATH "/tmp/citrun.shared"

static int init = 0;
static int shm_fd = 0;
static size_t shm_len = 0;

static size_t
add_1(uint8_t *shm, size_t shm_pos, uint8_t data)
{
	shm[shm_pos] = data;
	return shm_pos + sizeof(data);
}

static size_t
add_2(uint8_t *shm, size_t shm_pos, uint16_t data)
{
	memcpy(shm + shm_pos, &data, sizeof(data));
	return shm_pos + sizeof(data);
}

static size_t
add_4(uint8_t *shm, size_t shm_pos, uint32_t data)
{
	memcpy(shm + shm_pos, &data, sizeof(data));
	return shm_pos + sizeof(data);
}

static size_t
add_str(uint8_t *shm, size_t shm_pos, const char *str, uint16_t len)
{
	memcpy(shm + shm_pos, str, len);
	return shm_pos + len;
}

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
 * Add a header region to a newly created shared memory file. It contains:
 * - 6 byte magic value
 * - 2 bytes for major and minor versions
 * - 12 bytes for process id, parent process id, group process id
 * - 2 + N bytes for program name prefixed with its length
 * - 2 + N bytes for current working directory prefixed with its length
 * Header size is rounded up to next page size multiple. Exits on error.
 */
static void
shm_add_header()
{
	char		 magic[6] = "citrun";
	char		*cwd_buf;
	const char	*progname;
	uint8_t		*shm;
	size_t		 sz;
	size_t		 shm_pos;
	uint16_t	 prog_sz, cwd_sz;

	progname = getprogname();
	if ((cwd_buf = getcwd(NULL, 0)) == NULL)
		err(1, "getcwd");

	prog_sz = strnlen(progname, PATH_MAX);
	cwd_sz = strnlen(cwd_buf, PATH_MAX);

	sz = 0;
	sz += sizeof(magic);
	sz += sizeof(uint8_t) * 2;
	sz += sizeof(uint32_t) * 3;
	sz += sizeof(prog_sz);
	sz += prog_sz;
	sz += sizeof(cwd_sz);
	sz += cwd_sz;

	shm = shm_extend(sz);

	shm_pos = 0;
	shm_pos = add_str(shm, shm_pos, magic, sizeof(magic));

	shm_pos = add_1(shm, shm_pos, citrun_major);
	shm_pos = add_1(shm, shm_pos, citrun_minor);

	shm_pos = add_4(shm, shm_pos, getpid());
	shm_pos = add_4(shm, shm_pos, getppid());
	shm_pos = add_4(shm, shm_pos, getpgrp());

	shm_pos = add_2(shm, shm_pos, prog_sz);
	shm_pos = add_str(shm, shm_pos, progname, prog_sz);

	shm_pos = add_2(shm, shm_pos, cwd_sz);
	shm_pos = add_str(shm, shm_pos, cwd_buf, cwd_sz);

	assert(shm_pos == sz);
}

/*
 * Adds a new citrun_node to the shared memory file. Contains:
 * - 4 bytes for the number of source code lines
 * - 2 + N bytes for the file name used when compiling the source code
 * - 2 + N bytes for the source code's absolute file path
 * - 8 * L bytes (L = total number of source code lines) for the execution
 *   count buffers that store how many times each source code line executed.
 * Node size is rounded up to the next page size multiple.
 * Function exits on failure.
 */
static void
shm_add_node(struct citrun_node *n)
{
	uint8_t		*shm;
	size_t		 sz;
	size_t		 shm_pos;
	uint16_t	 comp_sz, abs_sz;

	comp_sz = strnlen(n->comp_file_path, PATH_MAX);
	abs_sz = strnlen(n->abs_file_path, PATH_MAX);

	sz = 0;
	sz += sizeof(uint32_t);
	sz += sizeof(comp_sz);
	sz += comp_sz;
	sz += sizeof(abs_sz);
	sz += abs_sz;
	sz += n->size * sizeof(uint64_t);

	shm = shm_extend(sz);

	shm_pos = 0;
	shm_pos = add_4(shm, shm_pos, n->size);
	shm_pos = add_2(shm, shm_pos, comp_sz);
	shm_pos = add_str(shm, shm_pos, n->comp_file_path, comp_sz);
	shm_pos = add_2(shm, shm_pos, abs_sz);
	shm_pos = add_str(shm, shm_pos, n->abs_file_path, abs_sz);

	n->data = (uint64_t *)&shm[shm_pos];
	shm_pos += n->size * sizeof(uint64_t);

	assert(shm_pos == sz);
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
 * Public interface: Add a node to shared memory.
 * Exits on failure.
 */
void
citrun_node_add(uint8_t node_major, uint8_t node_minor, struct citrun_node *n)
{
	/*
	 * Binary compatibility between versions is not guaranteed.
	 * A user is forced to rebuild their project in this case.
	 */
	if (node_major != citrun_major || node_minor != citrun_minor)
		errx(1, "libcitrun %i.%i: incompatible node version %i.%i",
			citrun_major, citrun_minor, node_major, node_minor);

	if (!init)
		shm_create();

	shm_add_node(n);
}
