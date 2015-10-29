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

	new_fd = ::accept(fd, (struct sockaddr *)&addr, &len);
	if (new_fd == -1) {
		if (errno != EWOULDBLOCK) {
			perror("accept");
		}
		return NULL;
	}

	std::cout << "accepted new connection" << std::endl;
	return new af_unix_nonblock(new_fd);
}

void
af_unix_nonblock::read()
{
	int nread;

	nread = ::read(fd, buffer, sizeof buffer);
	if (nread == 0) {
		// don't try to read from this socket anymore
		std::cerr << __func__ << ": eof read!" << std::endl;
	}
	if (nread > 0)
		std::cout << __func__ << ": read " << nread << " bytes" << std::endl;
	if (nread == -1)
		if (errno != EAGAIN)
			std::cerr << __func__ << ": read() failed: "
				<< strerror(errno) << std::endl;
}

af_unix_nonblock::~af_unix_nonblock()
{
	close(fd);
	unlink("socket");
}
