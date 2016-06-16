#include <assert.h>
#include <err.h>		/* err, errx, warnx */
#include <limits.h>		/* PATH_MAX */
#include <pthread.h>		/* pthread_create */
#include <stdlib.h>		/* getenv */
#include <string.h>
#include <sys/socket.h>
#include <sys/un.h>
#if __APPLE__
#include <sys/types.h>		/* read */
#include <sys/uio.h>		/* read */
#endif
#include <unistd.h>		/* read, getpid, getppid, getpgrp */

#include "runtime.h"

/* Entrance into instrumented application. */
extern struct citrun_node *citrun_nodes[];
extern uint64_t citrun_nodes_total;

/* Make sure instrumented programs rely on this library in some way. */
int needs_to_link_against_libcitrun;

static void send_metadata(int);
static void send_execution_data(int);
static int xread(int d, const void *buf, size_t bytes_total);
static int xwrite(int d, const void *buf, size_t bytes_total);

/* Sets up connection to the server socket and drops into an io loop. */
static void *
control_thread(void *arg)
{
	struct sockaddr_un addr;
	char *viewer_sock = NULL;
	int fd;
	uint8_t response;

	if ((fd = socket(AF_UNIX, SOCK_STREAM, 0)) == -1)
		err(1, "socket");

	/* The default socket location can be overridden */
	if ((viewer_sock = getenv("CITRUN_SOCKET")) == NULL)
		/* There was an error getting the env var, use the default */
		viewer_sock = "/tmp/citrun-gl.socket";

	/* Connect the socket to the server */
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

/* Walk the node array and send all of the static metadata information. */
static void
send_metadata(int fd)
{
	struct citrun_node walk;
	pid_t pids[3];
	size_t file_name_sz;
	int i;

	/* Send the total number of instrumented nodes. */
	xwrite(fd, &citrun_nodes_total, sizeof(citrun_nodes_total));

	/* Send process id, parent process id, group process id. */
	pids[0] = getpid();
	pids[1] = getppid();
	pids[2] = getpgrp();

	assert(sizeof(pid_t) == 4);
	for (i = 0; i < (sizeof(pids) / sizeof(pids[0])); i++)
		xwrite(fd, &pids[i], sizeof(pid_t));

	/* Send instrumented object file information, consisting of: */
	for (i = 0; i < citrun_nodes_total; i++) {
		walk = *citrun_nodes[i];

		/* Length of the original source file name. */
		file_name_sz = strnlen(walk.file_name, PATH_MAX);
		xwrite(fd, &file_name_sz, sizeof(file_name_sz));

		/* The original source file name. */
		xwrite(fd, walk.file_name, file_name_sz);

		/* Size of the execution counters. */
		xwrite(fd, &walk.size, sizeof(walk.size));

		/* Number of instrumentation sites. */
		xwrite(fd, &walk.inst_sites, sizeof(walk.size));
	}
}

/*
 * For each link in the instrumented translation unit chain send the contents
 * of that links execution buffers.
 */
static void
send_execution_data(int fd)
{
	struct citrun_node walk;
	int i;

	for (i = 0; i < citrun_nodes_total; i++) {
		walk = *citrun_nodes[i];

		/* Write execution buffer, one 8 byte counter per source line */
		xwrite(fd, walk.lines_ptr, walk.size * sizeof(uint64_t));
	}
}

static int
xwrite(int d, const void *buf, size_t bytes_total)
{
	int bytes_left = bytes_total;
	int bytes_wrote = 0;
	ssize_t n;

	while (bytes_left > 0) {
		n = write(d, (uint8_t *)buf + bytes_wrote, bytes_left);

		if (n < 0)
			err(1, "write()");

		bytes_wrote += n;
		bytes_left -= n;
	}

	return bytes_wrote;
}

static int
xread(int d, const void *buf, size_t bytes_total)
{
	ssize_t bytes_left = bytes_total;
	size_t bytes_read = 0;
	ssize_t n;

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

/* Grab an execution context and start up the control thread.  */
__attribute__((constructor))
static void runtime_init()
{
	pthread_t tid;
	pthread_create(&tid, NULL, control_thread, NULL);
}
