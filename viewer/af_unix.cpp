#include <err.h>		// err
#include <string.h>		// memset
#include <sys/socket.h>		// socket
#include <sys/un.h>		// sockaddr_un
#include <unistd.h>		// close

#include <iostream>

#include "af_unix.h"

af_unix_nonblock::af_unix_nonblock()
{
	if ((listen_fd = socket(AF_UNIX, SOCK_STREAM | SOCK_NONBLOCK, 0)) == -1)
		err(1, "socket");

	struct sockaddr_un addr;
	memset(&addr, 0, sizeof(addr));
	addr.sun_family = AF_UNIX;
	strncpy(addr.sun_path, "socket", sizeof(addr.sun_path) - 1);

	if (bind(listen_fd, (struct sockaddr *)&addr, sizeof(addr)))
		err(1, "bind");

	if (listen(listen_fd, 1024))
		err(1, "listen");
}

void
af_unix_nonblock::accept_one()
{
	int new_fd;
	struct sockaddr_un addr;
	socklen_t len = sizeof(struct sockaddr_un);

	new_fd = accept(listen_fd, (struct sockaddr *)&addr, &len);
	if (new_fd == -1) {
		if (errno != EWOULDBLOCK) {
			perror("accept");
		}
		return;
	}

	connected_fds.push_back(new_fd);
	std::cout << "accepted new connection" << std::endl;
}

void
af_unix_nonblock::read()
{
	char buffer[512];
	int nread;

	if (connected_fds.size() == 0)
		return;

	nread = ::read(connected_fds[0], buffer, sizeof buffer);
	if (nread == 0) {
		// don't try to read from this socket anymore
		connected_fds.clear();
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
	close(listen_fd);
	unlink("socket");
}
