#include <err.h>		// err
#include <string.h>		// memset
#include <sys/socket.h>		// socket
#include <sys/un.h>		// sockaddr_un
#include <unistd.h>		// close

#include <iostream>

#include "af_unix.h"

af_unix_nonblock::af_unix_nonblock()
{
}

af_unix_nonblock::af_unix_nonblock(int f) :
	fd(f)
{
}

void
af_unix_nonblock::set_listen()
{
	if ((fd = socket(AF_UNIX, SOCK_STREAM | SOCK_NONBLOCK, 0)) == -1)
		err(1, "socket");

	struct sockaddr_un addr;
	memset(&addr, 0, sizeof(addr));
	addr.sun_family = AF_UNIX;
	strncpy(addr.sun_path, "socket", sizeof(addr.sun_path) - 1);

	if (bind(fd, (struct sockaddr *)&addr, sizeof(addr)))
		err(1, "bind");

	if (listen(fd, 1024))
		err(1, "listen");
}

af_unix_nonblock *
af_unix_nonblock::accept()
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

	std::cerr << "accepted new connection" << std::endl;
	return new af_unix_nonblock(new_fd);
}

int
af_unix_nonblock::write_all(uint8_t *buf, size_t bytes_total)
{
	int bytes_left = bytes_total;
	int bytes_wrote = 0;
	ssize_t n;

	while (bytes_left > 0) {
		n = write(fd, buf + bytes_wrote, bytes_left);

		if (n < 0 && errno == EAGAIN)
			/* Do not try to continue writing data */
			break;
		if (n < 0)
			err(1, "write()");

		bytes_wrote += n;
		bytes_left -= n;
	}

	return bytes_wrote;
}

int
af_unix_nonblock::read_all(uint8_t *buf, size_t bytes_total)
{
	int bytes_left = bytes_total;
	int bytes_read = 0;
	ssize_t n;

	while (bytes_left > 0) {
		n = read(fd, buf + bytes_read, bytes_left);

		if (n == 0)
			errx(1, "read(): read 0 bytes on socket");
		if (n < 0 && errno != EAGAIN)
			err(1, "read()");
		if (n < 0 && errno == EAGAIN)
			/* Do not try to continue reading data */
			break;

		bytes_read += n;
		bytes_left -= n;
	}

	return bytes_read;
}

af_unix_nonblock::~af_unix_nonblock()
{
	close(fd);
	unlink("socket");
}
