#include <err.h>
#include <pthread.h>
#include <stdio.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/un.h>

#include <scv_global.h>

/* Entry point into instrumented application */
extern struct scv_node node0;

void send_metadata(int);
void send_execution_data(int);


void *
control_thread(void *arg)
{
	int fd;
	int i;

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

	while (1) {
		uint8_t msg_type;
		xread(fd, &msg_type, 1);

		if (msg_type == 0)
			send_metadata(fd);
		else if (msg_type == 1)
			send_execution_data(fd);
		else
			errx(1, "unknown message type %i", msg_type);
	}
}

__attribute__((constructor))
static void runtime_init()
{
	pthread_t tid;
	pthread_create(&tid, NULL, control_thread, NULL);
}

void
send_metadata(int fd)
{
	size_t file_name_sz;
	uint64_t num_tus = 0;
	struct scv_node walk = node0;

	while (walk.size != 0) {
		++num_tus;
		walk = *walk.next;
	}

	xwrite(fd, &num_tus, sizeof(num_tus));

	walk = node0;
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
	struct scv_node walk = node0;

	while (walk.size != 0) {
		/* Write execution buffer, one 8 byte counter per source line */
		xwrite(fd, walk.lines_ptr, walk.size * sizeof(uint64_t));
		walk = *walk.next;
	}
}

int
xwrite(int d, const uint8_t *buf, size_t bytes_total)
{
	int bytes_left = bytes_total;
	int bytes_wrote = 0;
	ssize_t n;

	while (bytes_left > 0) {
		n = write(d, buf + bytes_wrote, bytes_left);

		if (n < 0)
			err(1, "write()");

		bytes_wrote += n;
		bytes_left -= n;
	}

	return bytes_wrote;
}

int
xread(int d, uint8_t *buf, size_t bytes_total)
{
	ssize_t bytes_left = bytes_total;
	size_t bytes_read = 0;
	ssize_t n;

	while (bytes_left > 0) {
		n = read(d, buf + bytes_read, bytes_left);

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
