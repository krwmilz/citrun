#include <err.h>
#include <pthread.h>
#include <stdio.h>
#include <string.h>
#include <sys/socket.h>		// AF_UNIX
#include <sys/un.h>		// sockaddr_un

#include <scv_global.h>

/* Entry point into instrumented application */
extern struct scv_node node0;

void walk_nodes(int);


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
	strncpy(addr.sun_path, "/tmp/viewer_test.socket", sizeof(addr.sun_path) - 1);

	if (connect(fd, (struct sockaddr *)&addr, sizeof(addr))) {
		err(1, "connect");
		return 0;
	}

	while (1) {
		uint8_t msg_type;
		xread(fd, &msg_type, 1);

		if (msg_type == 0)
			walk_nodes(fd);
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
walk_nodes(int fd)
{
	size_t file_name_sz;

	/* Copy node0, don't use it directly */
	struct scv_node walk = node0;
	while (walk.size != 0) {
		file_name_sz = strnlen(walk.file_name, PATH_MAX);

		/* Send file name size and then the file name itself. */
		xwrite(fd, &file_name_sz, sizeof(file_name_sz));
		xwrite(fd, walk.file_name, file_name_sz);

		/* Send the contents of the coverage buffer */
		xwrite(fd, &walk.size, sizeof(uint64_t));
		xwrite(fd, walk.lines_ptr, walk.size * sizeof(uint64_t));

		walk = *walk.next;
	}
}

int
xwrite(int d, const void *buf, size_t bytes_total)
{
	int bytes_left;
	int bytes_wrote;
	ssize_t n;

	bytes_left = bytes_total;
	bytes_wrote = 0;
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
xread(int d, void *buf, size_t bytes_total)
{
	ssize_t bytes_left;
	size_t bytes_read;
	ssize_t n;

	bytes_left = bytes_total;
	bytes_read = 0;
	while (bytes_left > 0) {
		n = read(d, buf + bytes_read, bytes_left);

		/* Disconnect */
		if (n == 0)
			err(1, "read 0 bytes on socket");
		if (n < 0)
			err(1, "read()");

		bytes_read += n;
		bytes_left -= n;
	}

	return bytes_read;
}
