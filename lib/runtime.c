#include <assert.h>
#include <err.h>
#include <limits.h>		// PATH_MAX
#include <pthread.h>
#include <stdio.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/un.h>
#if __APPLE__
#include <sys/types.h>		// read
#include <sys/uio.h>		// read
#endif
#include <unistd.h>		// read, getpid, getppid, getpgrp

#include "runtime.h"

/* Entry point into instrumented application */
extern struct _scv_node _scv_node0;

void send_metadata(int);
void send_execution_data(int);

int xread(int d, const void *buf, size_t bytes_total);
int xwrite(int d, const void *buf, size_t bytes_total);

/*
 * Dummy function to make sure that the instrumented program gets linked against
 * this library.
 * Linux likes to liberally discard -l... flags given when linking.
 */
void
libscv_init()
{
}

void *
control_thread(void *arg)
{
	int fd;
	int i;
	uint8_t response;

	fd = socket(AF_UNIX, SOCK_STREAM, 0);
	if (fd == -1)
		err(1, "socket");

	struct sockaddr_un addr;
	memset(&addr, 0, sizeof(addr));
	addr.sun_family = AF_UNIX;
	strncpy(addr.sun_path, "viewer_test.socket", sizeof(addr.sun_path) - 1);

	if (connect(fd, (struct sockaddr *)&addr, sizeof(addr))) {
		err(1, "connect");
	}

	/* Send metadata first */
	send_metadata(fd);

	/* Then synchronously send execution data */
	while (1) {
		send_execution_data(fd);
		xread(fd, &response, 1);
	}
}

void
send_metadata(int fd)
{
	size_t file_name_sz;
	uint64_t num_tus = 0;
	struct _scv_node walk = _scv_node0;

	/* Send the total number of translation unit records we'll send later */
	while (walk.size != 0) {
		++num_tus;
		walk = *walk.next;
	}
	xwrite(fd, &num_tus, sizeof(num_tus));

	/* Send process id, parent process id and group process id. */
	pid_t process_id = getpid();
	pid_t parent_process_id = getppid();
	pid_t process_group = getpgrp();

	assert(sizeof(pid_t) == 4);
	xwrite(fd, &process_id, sizeof(pid_t));
	xwrite(fd, &parent_process_id, sizeof(pid_t));
	xwrite(fd, &process_group, sizeof(pid_t));

	walk = _scv_node0;
	/* Send translation unit records */
	while (walk.size != 0) {
		/* Send file name size and then the file name itself. */
		file_name_sz = strnlen(walk.file_name, PATH_MAX);
		xwrite(fd, &file_name_sz, sizeof(file_name_sz));
		xwrite(fd, walk.file_name, file_name_sz);

		/* Send the size of the execution buffers */
		xwrite(fd, &walk.size, sizeof(walk.size));

		walk = *walk.next;
	}
}

void
send_execution_data(int fd)
{
	struct _scv_node walk = _scv_node0;

	while (walk.size != 0) {
		/* Write execution buffer, one 8 byte counter per source line */
		xwrite(fd, walk.lines_ptr, walk.size * sizeof(uint64_t));
		walk = *walk.next;
	}
}

int
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

int
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

__attribute__((constructor))
static void runtime_init()
{
	pthread_t tid;
	pthread_create(&tid, NULL, control_thread, NULL);
}
