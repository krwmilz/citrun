#include <err.h>		// err
#include <fcntl.h>
#include <string.h>		// memset
#include <sys/socket.h>		// socket
#include <sys/un.h>		// sockaddr_un
#include <unistd.h>		// close

#include <iostream>

#include "af_unix.h"

af_unix::af_unix()
{
}

af_unix::af_unix(int f) :
	fd(f)
{
}

void
af_unix::set_listen()
{
	if ((fd = socket(AF_UNIX, SOCK_STREAM | SOCK_NONBLOCK, 0)) == -1)
		err(1, "socket");

	struct sockaddr_un addr;
	memset(&addr, 0, sizeof(addr));
	addr.sun_family = AF_UNIX;
	strncpy(addr.sun_path, "../while/viewer_test.socket", sizeof(addr.sun_path) - 1);

	if (bind(fd, (struct sockaddr *)&addr, sizeof(addr)))
		err(1, "bind");

	if (listen(fd, 1024))
		err(1, "listen");
}

af_unix *
af_unix::accept()
{
	int new_fd;
	struct sockaddr_un addr;
	socklen_t len = sizeof(struct sockaddr_un);

	// Namespace collision
	new_fd = ::accept(fd, (struct sockaddr *)&addr, &len);
	if (new_fd == -1) {
		if (errno != EWOULDBLOCK) {
			perror("accept");
		}
		return NULL;
	}

	// Turn off non blocking mode
	int flags = fcntl(new_fd, F_GETFL, 0);
	if (flags < 0)
		err(1, "fcntl(F_GETFL)");
	fcntl(new_fd, F_SETFL, flags & ~O_NONBLOCK);
	if (flags < 0)
		err(1, "fcntl(F_SETFL)");

	std::cerr << "accepted new connection" << std::endl;
	return new af_unix(new_fd);
}

int
af_unix::write_all(uint8_t *buf, size_t bytes_total)
{
	int bytes_left = bytes_total;
	int bytes_wrote = 0;
	ssize_t n;

	while (bytes_left > 0) {
		n = write(fd, buf + bytes_wrote, bytes_left);

		if (n < 0)
			err(1, "write()");

		bytes_wrote += n;
		bytes_left -= n;
	}

	return bytes_wrote;
}

int
af_unix::read_all(uint64_t &buf)
{
	int bytes_left = sizeof(uint64_t);
	int bytes_read = 0;
	ssize_t n;

	while (bytes_left > 0) {
		n = read(fd, &buf + bytes_read, bytes_left);

		if (n == 0)
			errx(1, "read(): read 0 bytes on socket");
		if (n < 0)
			err(1, "read()");

		bytes_read += n;
		bytes_left -= n;
	}

	return bytes_read;
}

int
af_unix::read_all(uint8_t *buf, size_t bytes_total)
{
	int bytes_left = bytes_total;
	int bytes_read = 0;
	ssize_t n;

	while (bytes_left > 0) {
		n = read(fd, buf + bytes_read, bytes_left);

		if (n == 0)
			errx(1, "read(): read 0 bytes on socket");
		if (n < 0)
			err(1, "read()");

		bytes_read += n;
		bytes_left -= n;
	}

	return bytes_read;
}

af_unix::~af_unix()
{
	close(fd);
	unlink("../while/viewer_test.socket");
}
