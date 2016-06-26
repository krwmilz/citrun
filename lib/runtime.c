#include <assert.h>
#include <err.h>		/* err, errx, warn */
#include <limits.h>		/* PATH_MAX */
#include <pthread.h>		/* pthread_create */
#include <stdlib.h>		/* getenv */
#include <string.h>		/* strlcpy */
#include <unistd.h>		/* getpid, getppid, getpgrp, read, write */

#include <sys/socket.h>		/* socket */
#include <sys/un.h>		/* sockaddr_un */
#if __APPLE__
#include <sys/types.h>		/* read */
#include <sys/uio.h>		/* read */
#endif

#include "runtime.h"

static struct citrun_node *nodes_head;
static struct citrun_node *nodes_tail;
static uint64_t nodes_total;

static void *control_thread(void *);

/*
 * Public interface.
 */

void
citrun_node_add(struct citrun_node *n)
{
	if (nodes_head == NULL) {
		assert(nodes_tail == NULL);
		nodes_head = n;
		nodes_tail = n;
		return;
	}

	nodes_tail->next = n;
	nodes_tail = n;
}

void
citrun_start()
{
	struct citrun_node	*w;
	nodes_total = 0;

	/*
	 * Count nodes once. Changing this after program start is not supported
	 * at the moment.
	 */
	for (w = nodes_head; w != NULL; w = w->next)
		++nodes_total;

	pthread_t tid;
	pthread_create(&tid, NULL, control_thread, NULL);
}

/*
 * Private interface.
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


/* Walk the node array and send all of the static metadata information. */
static void
send_metadata(int fd)
{
	struct citrun_node	*w;
	struct citrun_node	 node;
	pid_t			 pids[3];
	size_t			 file_name_sz;
	int			 i;

	/* Send the total number of translation units. */
	xwrite(fd, &nodes_total, sizeof(nodes_total));

	/* Send process id, parent process id, group process id. */
	pids[0] = getpid();
	pids[1] = getppid();
	pids[2] = getpgrp();

	assert(sizeof(pid_t) == 4);
	for (i = 0; i < (sizeof(pids) / sizeof(pids[0])); i++)
		xwrite(fd, &pids[i], sizeof(pid_t));

	/* Send static object file information. */
	for (i = 0, w = nodes_head; i < nodes_total, w != NULL; i++, w = w->next) {
		node = *w;

		/* Length of the original source file name. */
		file_name_sz = strnlen(node.file_name, PATH_MAX);
		xwrite(fd, &file_name_sz, sizeof(file_name_sz));

		/* The original source file name. */
		xwrite(fd, node.file_name, file_name_sz);

		/* Size of the execution counters. */
		xwrite(fd, &node.size, sizeof(node.size));

		/* Number of instrumentation sites. */
		xwrite(fd, &node.inst_sites, sizeof(node.size));
	}

	if (i != nodes_total)
		warnx("tu chain inconsistent: %i vs %i", i, nodes_total);
	if (w != NULL)
		warnx("tu chain is longer than before");
}

/*
 * For each link in the instrumented translation unit chain send the contents
 * of that links execution buffers.
 */
static void
send_execution_data(int fd)
{
	struct citrun_node	*w;
	int			 i;

	/* Write execution buffers (one 8 byte counter per source line). */
	for (i = 0, w = nodes_head; i < nodes_total, w != NULL; i++, w = w->next)
		xwrite(fd, w->lines_ptr, w->size * sizeof(uint64_t));

	if (i != nodes_total)
		warnx("tu chain inconsistent: %i vs %i", i, nodes_total);
	if (w != NULL)
		warnx("tu chain is longer than before");
}

/* Sets up connection to the server socket and drops into an io loop. */
static void *
control_thread(void *arg)
{
	struct sockaddr_un	 addr;
	char			*viewer_sock = NULL;
	int			 fd;
	uint8_t			 response;

	if ((fd = socket(AF_UNIX, SOCK_STREAM, 0)) == -1)
		err(1, "socket");

	if ((viewer_sock = getenv("CITRUN_SOCKET")) == NULL)
		viewer_sock = "/tmp/citrun-gl.socket";

	memset(&addr, 0, sizeof(addr));
	addr.sun_family = AF_UNIX;
	strlcpy(addr.sun_path, viewer_sock, sizeof(addr.sun_path));

	while (1) {
		if (connect(fd, (struct sockaddr *)&addr, sizeof(addr))) {
			warn("connect");
			sleep(1);
			continue;
		}

		/* Send static information first. */
		send_metadata(fd);

		while (1) {
			/* Synchronously send execution data */
			send_execution_data(fd);
			xread(fd, &response, 1);
		}
	}
}
