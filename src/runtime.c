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
#include <sys/mman.h>		/* shm_open, mmap */
#include <sys/stat.h>		/* S_*USR */

#include <assert.h>
#include <err.h>
#include <fcntl.h>		/* O_CREAT */
#include <limits.h>		/* PATH_MAX */
#include <string.h>		/* strnlen */
#include <unistd.h>		/* get{cwd,pid,ppid,pgrp} */

#include "runtime.h"
#include "version.h"

#define SHM_PATH "/tmp/citrun.shared"

static int init = 0;
static int shm_fd = 0;
static size_t shm_len = 0;

__attribute__((destructor))
static void clean_up()
{
	(void) shm_unlink(SHM_PATH);
}

size_t
add_1(uint8_t *shm, size_t shm_pos, uint8_t data)
{
	shm[shm_pos] = data;
	return shm_pos + 1;
}

size_t
add_4(uint8_t *shm, size_t shm_pos, uint32_t data)
{
	memcpy(shm + shm_pos, &data, 4);
	return shm_pos + 4;
}

size_t
add_str(uint8_t *shm, size_t shm_pos, const char *str, uint16_t null_len)
{
	strlcpy(shm + shm_pos, str, null_len);
	return shm_pos + null_len;
}

/*
 * These are written into shared memory, offset 0:
 * - version major and minor
 * - total number of translation units
 * - process id, parent process id, group process id
 * - length of program name
 * - program name
 * - length of current working directory
 * - current working directory
 */
static void
write_header()
{
	char		*cwd_buf;
	const char	*progname;
	size_t		 sz = 0;
	uint16_t	 prog_sz, cwd_sz;

	progname = getprogname();
	if ((cwd_buf = getcwd(NULL, 0)) == NULL)
		err(1, "getcwd");

	prog_sz = strnlen(progname, PATH_MAX) + 1;
	cwd_sz = strnlen(cwd_buf, PATH_MAX) + 1;

	sz += sizeof(uint8_t) * 2;
	sz += sizeof(uint32_t) * 3;
	sz += prog_sz;
	sz += cwd_sz;

	if (ftruncate(shm_fd, sz) < 0)
		err(1, "ftruncate");

	uint8_t *shm = mmap(NULL, sz, PROT_READ | PROT_WRITE, MAP_SHARED, shm_fd, 0);
	if (shm == MAP_FAILED)
		err(1, "mmap");
	shm_len = sz;

	size_t shm_pos = 0;
	shm_pos = add_1(shm, shm_pos, citrun_major);
	shm_pos = add_1(shm, shm_pos, citrun_minor);

	shm_pos = add_4(shm, shm_pos, getpid());
	shm_pos = add_4(shm, shm_pos, getppid());
	shm_pos = add_4(shm, shm_pos, getpgrp());

	shm_pos = add_str(shm, shm_pos, progname, prog_sz);
	shm_pos = add_str(shm, shm_pos, cwd_buf, cwd_sz);

	assert(shm_pos == sz);
}

/*
 * Operates on global shm_fd.
 */
static int
get_shm_fd()
{
	assert(shm_fd >= 0);

	if (shm_fd > 0)
		return shm_fd;

	if ((shm_fd = shm_open(SHM_PATH, O_CREAT | O_EXCL | O_RDWR, S_IRUSR | S_IWUSR)) < 0)
		err(1, "shm_open");

	if (init > 0)
		errx(1, "init > 0!");

	write_header();

	init++;
	return shm_fd;
}


/*
 * Public interface: Add a node to shared memory.
 */
void
citrun_node_add(uint8_t node_major, uint8_t node_minor, struct citrun_node *n)
{
	int fd;
	size_t sz = 0;
	size_t comp_sz, abs_sz;
	uint8_t *shm;
	size_t shm_pos = 0;

	if (node_major != citrun_major || node_minor != citrun_minor) {
		warnx("libcitrun %i.%i: node with version %i.%i skipped",
			citrun_major, citrun_minor,
			node_major, node_minor);
		return;
	}

	fd = get_shm_fd();

	comp_sz = strnlen(n->comp_file_path, PATH_MAX) + 1;
	abs_sz = strnlen(n->abs_file_path, PATH_MAX) + 1;

	sz += sizeof(uint8_t);
	sz += sizeof(uint32_t);
	sz += comp_sz;
	sz += abs_sz;
	sz += n->size * sizeof(uint64_t);

	/* Extend the file for new node + line counts. */
	if (ftruncate(fd, shm_len + sz) < 0)
		err(1, "ftruncate");

	shm = mmap(NULL, sz, PROT_READ | PROT_WRITE, MAP_SHARED, fd, shm_len);
	if (shm == MAP_FAILED)
		err(1, "mmap");
	shm_len += sz;

	/* Skip past the 'ready' bit location. */
	size_t ready_bit = shm_pos;
	shm_pos += 1;

	shm_pos = add_4(shm, shm_pos, n->size);
	shm_pos = add_str(shm, shm_pos, n->comp_file_path, comp_sz);
	shm_pos = add_str(shm, shm_pos, n->abs_file_path, abs_sz);

	n->data = (uint64_t *)&shm[shm_pos];
	shm_pos += n->size * sizeof(uint64_t);

	assert(shm_pos == sz);

	/* Flip the ready bit. */
	shm[ready_bit] = 1;
}
