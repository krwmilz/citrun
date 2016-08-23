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
#include <sys/stat.h>		/* S_IRUSR, S_IWUSR, mkdir */

#include <assert.h>
#include <err.h>
#include <errno.h>
#include <fcntl.h>		/* O_CREAT */
#include <limits.h>		/* PATH_MAX */
#include <stdlib.h>		/* get{env,progname} */
#include <string.h>		/* strnlen */
#include <unistd.h>		/* get{cwd,pid,ppid,pgrp} */

#include "runtime.h"
#include "version.h"

#define SHM_PATH "/tmp/citrun.shared"

static int init = 0;
static int shm_fd = 0;
static size_t shm_len = 0;

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
	strlcpy((char *)shm + shm_pos, str, null_len);
	return shm_pos + null_len;
}

static uint8_t *
add_new_region(int bytes)
{
	uint8_t		*shm;
	int		 page_size = getpagesize();
	int		 page_mask = page_size - 1;
	int		 aligned_bytes;

	aligned_bytes = ((bytes) + page_mask) & ~page_mask;

	if (ftruncate(shm_fd, shm_len + aligned_bytes) < 0)
		err(1, "ftruncate from %i to %i", shm_len, shm_len + aligned_bytes);

	shm = mmap(NULL, bytes, PROT_READ | PROT_WRITE, MAP_SHARED,
			shm_fd, shm_len);

	if (shm == MAP_FAILED)
		err(1, "mmap %i bytes @ %i", bytes, shm_len);

	shm_len += aligned_bytes;
	return shm;
}

/*
 * These are written into shared memory, offset 0:
 * - version major and minor
 * - process id, parent process id, group process id
 * - program name
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

	uint8_t *shm = add_new_region(sz);

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

static void
create_memory_file()
{
	assert(shm_fd == 0);
	assert(shm_len == 0);

#if 0
	if ((shm_path = getenv("CITRUN_SHMPATH")) == NULL)
		shm_path = SHM_PATH;
#endif

	/* Existing directory is OK. */
	if (mkdir("/tmp/citrun", S_IRWXU) && errno != EEXIST)
		err(1, "mkdir");

	char shm_path[23];
	strlcpy(shm_path, "/tmp/citrun/pid.XXXXXX", sizeof(shm_path));
	if ((shm_fd = mkstemp(shm_path)) == -1)
		err(1, "mkstemp");

	init++;
	write_header();
}


/*
 * Public interface: Add a node to shared memory.
 */
void
citrun_node_add(uint8_t node_major, uint8_t node_minor, struct citrun_node *n)
{
	size_t sz = 0;
	size_t comp_sz, abs_sz;
	uint8_t *shm;
	size_t shm_pos = 0;

	if (node_major != citrun_major || node_minor != citrun_minor) {
		errx(1, "libcitrun %i.%i: incompatible node version %i.%i",
			citrun_major, citrun_minor, node_major, node_minor);
	}

	if (!init)
		create_memory_file();

	comp_sz = strnlen(n->comp_file_path, PATH_MAX) + 1;
	abs_sz = strnlen(n->abs_file_path, PATH_MAX) + 1;

	sz += sizeof(uint8_t);
	sz += sizeof(uint32_t);
	sz += comp_sz;
	sz += abs_sz;
	sz += n->size * sizeof(uint64_t);

	shm = add_new_region(sz);

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
