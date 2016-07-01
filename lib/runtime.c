#include <assert.h>
#include <err.h>		/* err, errx, warn */
#include <limits.h>		/* PATH_MAX */
#include <pthread.h>		/* pthread_create */
#include <stdlib.h>		/* getenv */
#include <string.h>		/* strlcpy */
#include <unistd.h>		/* access, get{pid,ppid,pgrp}, read, write */

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

static void *relay_thread(void *);

/*
 * Add a node to the end of the list. Public interface.
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

/*
 * Usually called from main(), starts the relay thread. Public interface.
 */
void
citrun_start()
{
	struct citrun_node	*w;
	pthread_t		 tid;

	/*
	 * Count nodes once. Changing this after program start is not supported
	 * at the moment (dlopen(), dlclose() of instrumented libs).
	 */
	nodes_total = 0;
	for (w = nodes_head; w != NULL; w = w->next)
		++nodes_total;

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
 * Sent fields:
 * - total number of translation units
 * - process id, parent process id, group process id
 * - length of the original source file name
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
	size_t			 file_name_sz;
	int			 i;

	xwrite(fd, &nodes_total, sizeof(nodes_total));

	pids[0] = getpid();
	pids[1] = getppid();
	pids[2] = getpgrp();
	assert(sizeof(pid_t) == 4);
	for (i = 0; i < (sizeof(pids) / sizeof(pids[0])); i++)
		xwrite(fd, &pids[i], sizeof(pid_t));

	for (i = 0, w = nodes_head; i < nodes_total && w != NULL; i++, w = w->next) {
		node = *w;

		file_name_sz = strnlen(node.file_name, PATH_MAX);
		xwrite(fd, &file_name_sz, sizeof(file_name_sz));
		xwrite(fd, node.file_name, file_name_sz);
		xwrite(fd, &node.size, sizeof(node.size));
		xwrite(fd, &node.inst_sites, sizeof(node.size));
	}

	if (i != nodes_total)
		warnx("tu chain inconsistent: %i vs %llu", i, nodes_total);
	if (w != NULL)
		warnx("tu chain is longer than before");
}

/*
 * For each node in the chain send the dynamic line count data.
 */
static void
send_dynamic(int fd)
{
	struct citrun_node	*w;
	int			 i;

	/* Write execution buffers (one 8 byte counter per source line). */
	for (i = 0, w = nodes_head; i < nodes_total && w != NULL; i++, w = w->next)
		xwrite(fd, w->lines_ptr, w->size * sizeof(uint64_t));

	if (i != nodes_total)
		warnx("tu chain inconsistent: %i vs %llu", i, nodes_total);
	if (w != NULL)
		warnx("tu chain is longer than before");
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
