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
#include <sys/socket.h>		/* socket */
#include <sys/un.h>		/* sockaddr_un */
#if __APPLE__
#include <sys/types.h>		/* read */
#include <sys/uio.h>		/* read */
#endif

#include <assert.h>
#include <err.h>		/* err, errx, warn */
#include <limits.h>		/* PATH_MAX */
#include <pthread.h>		/* pthread_create */
#include <stdlib.h>		/* getenv */
#include <string.h>		/* strlcpy */
#include <unistd.h>		/* access, get{pid,ppid,pgrp}, read, write */

#include "runtime.h"

static struct citrun_node	*nodes_head;
static uint64_t			 nodes_total;
static uint64_t			 lines_total;

static void *relay_thread(void *);

/*
 * Public interface: Insert a node into the sorted translation unit list.
 */
void
citrun_node_add(struct citrun_node *n)
{
	struct citrun_node *walk = nodes_head;

	/* Used for double buffering line counts. */
	n->old_lines = calloc(n->size, sizeof(uint64_t));
	if (n->old_lines == NULL)
		err(1, "calloc");

	nodes_total++;
	lines_total += n->size;

	/* If the list is empty or we need to replace the list head */
	if (nodes_head == NULL || nodes_head->size >= n->size) {
		n->next = nodes_head;
		nodes_head = n;
		return;
	}

	/* Search for a next element that n->size is greater than */
	while (walk->next != NULL && walk->next->size < n->size)
		walk = walk->next;

	/* Splice in the new element after walk but before walk->next */
	n->next = walk->next;
	walk->next = n;
}

/*
 * Public interface: Called from instrumented main(), starts the relay thread.
 */
void
citrun_start()
{
	pthread_t		 tid;
	pthread_create(&tid, NULL, relay_thread, NULL);
}

/*
 * Read an exact amount of bytes. Returns number of bytes read.
 */
static int
xread(int d, const void *buf, size_t bytes_total)
{
	ssize_t	 bytes_left = bytes_total;
	size_t	 bytes_read = 0;
	ssize_t	 n;

	while (bytes_left > 0) {
		n = read(d, (uint8_t *)buf + bytes_read, bytes_left);

		if (n == 0)
			/* Disconnect */
			errx(1, "read 0 bytes on socket");
		if (n < 0)
			err(1, "read()");

		bytes_read += n;
		bytes_left -= n;
	}

	return bytes_read;
}

/*
 * Write an exact amount of bytes. Returns number of bytes written.
 */
static int
xwrite(int d, const void *buf, size_t bytes_total)
{
	int	 bytes_left = bytes_total;
	int	 bytes_wrote = 0;
	ssize_t	 n;

	while (bytes_left > 0) {
		n = write(d, (uint8_t *)buf + bytes_wrote, bytes_left);

		if (n < 0)
			err(1, "write()");

		bytes_wrote += n;
		bytes_left -= n;
	}

	return bytes_wrote;
}

/*
 * Send static information contained in each instrumented node.
 * Sent program wide values:
 * - length of program name
 * - program name
 * - total number of translation units
 * - total number of lines in program
 * - process id, parent process id, group process id
 * Sent for each instrumented translation unit:
 * - length of source file name
 * - source file name
 * - size of the execution counters
 * - number of instrumentation sites.
 */
static void
send_static(int fd)
{
	struct citrun_node	 node;
	pid_t			 pids[3];
	struct citrun_node	*w;
	const char		*progname;
	size_t			 sz;
	int			 i;

	progname = getprogname();
	sz = strlen(progname);

	xwrite(fd, &sz, sizeof(sz));
	xwrite(fd, progname, sz);
	xwrite(fd, &nodes_total, sizeof(nodes_total));
	xwrite(fd, &lines_total, sizeof(lines_total));

	pids[0] = getpid();
	pids[1] = getppid();
	pids[2] = getpgrp();
	assert(sizeof(pid_t) == 4);
	for (i = 0; i < (sizeof(pids) / sizeof(pids[0])); i++)
		xwrite(fd, &pids[i], sizeof(pid_t));

	for (w = nodes_head, i = 0; w != NULL; w = w->next, i++) {
		node = *w;
		sz = strnlen(node.file_name, PATH_MAX);

		xwrite(fd, &sz, sizeof(sz));
		xwrite(fd, node.file_name, sz);
		xwrite(fd, &node.size, sizeof(node.size));
		xwrite(fd, &node.inst_sites, sizeof(node.size));
	}
	assert(i == nodes_total);
	assert(w == NULL);
}

/*
 * For each node in the chain send the dynamic line count data.
 */
static void
send_dynamic(int fd)
{
	struct citrun_node	*w;
	uint64_t		*lines_ptr;
	uint64_t		*old_lines_ptr;
	int			 i;
	int			 line;

	/* Write execution buffers (one 8 byte counter per source line). */
	for (w = nodes_head, i = 0; w != NULL; w = w->next, i++) {

		lines_ptr = w->lines_ptr;
		old_lines_ptr = w->old_lines;
		for (line = 0; line < w->size; line++) {
			assert(lines_ptr[line] >= old_lines_ptr[line]);

			uint64_t diff = lines_ptr[line] - old_lines_ptr[line];
			/* Let's try incremental updating of old_lines. */
			old_lines_ptr[line] = lines_ptr[line];
			xwrite(fd, &diff, sizeof(uint64_t));
		}
	}
	assert(i == nodes_total);
	assert(w == NULL);
}

static void
fork_viewer()
{
	pid_t 		 pid;

	pid = fork();
	if (pid < 0)
		err(1, "fork");
	else if (pid == 0)
		execlp("citrun-gl", "citrun-gl", NULL);
	else
		warnx("socket not found, forking viewer");
}

/*
 * Relays line count data over a Unix domain socket.
 */
static void *
relay_thread(void *arg)
{
	struct sockaddr_un	 addr;
	char			*viewer_sock = NULL;
	int			 fd;
	uint8_t			 response;

	if ((fd = socket(AF_UNIX, SOCK_STREAM, 0)) == -1)
		err(1, "socket");

	if ((viewer_sock = getenv("CITRUN_SOCKET")) == NULL) {
		viewer_sock = "/tmp/citrun-gl.socket";

		/* Fork a viewer if the default socket path doesn't exist */
		if (access(viewer_sock, F_OK) < 0)
			fork_viewer();
	}

	memset(&addr, 0, sizeof(addr));
	addr.sun_family = AF_UNIX;
	strlcpy(addr.sun_path, viewer_sock, sizeof(addr.sun_path));

	while (1) {
		if (connect(fd, (struct sockaddr *)&addr, sizeof(addr))) {
			/* warn("connect"); */
			sleep(1);
			continue;
		}

		/* Send static information first. */
		send_static(fd);

		while (1) {
			/* Synchronously send changing data. */
			send_dynamic(fd);
			xread(fd, &response, 1);
		}
	}
}
