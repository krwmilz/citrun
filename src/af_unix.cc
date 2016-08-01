//
// Copyright (c) 2016 Kyle Milz <kyle@0x30.net>
//
// Permission to use, copy, modify, and distribute this software for any
// purpose with or without fee is hereby granted, provided that the above
// copyright notice and this permission notice appear in all copies.
//
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
// WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
// ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
// WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
// ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
// OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
//
#include <sys/socket.h>		// accept, socket
#include <sys/un.h>		// sockaddr_un

#include <cerrno>		// EWOULDBLOCK
#include <err.h>		// err
#include <cstring>		// memset, strlcpy
#include <fcntl.h>		// fcntl, F_GETFL
#include <stdexcept>
#include <system_error>		// system_error
#include <unistd.h>		// close, read

#include "af_unix.h"

af_unix::af_unix() :
	m_socket_path("/tmp/citrun.socket")
{
	if ((m_fd = socket(AF_UNIX, SOCK_STREAM, 0)) == -1)
		err(1, "socket");
}

af_unix::~af_unix()
{
	close(m_fd);
	if (m_bound)
		unlink(m_socket_path.c_str());
}

af_unix::af_unix(int f) :
	m_fd(f)
{
}

void
af_unix::set_nonblock()
{
	int flags;

	if ((flags = fcntl(m_fd, F_GETFL, 0)) < 0)
		err(1, "fcntl(F_GETFL)");
	if (fcntl(m_fd, F_SETFL, flags | O_NONBLOCK) < 0)
		err(1, "fcntl(F_SETFL)");
}

void
af_unix::set_block()
{
	int flags;

	if ((flags = fcntl(m_fd, F_GETFL, 0)) < 0)
		err(1, "fcntl(F_GETFL)");
	if (fcntl(m_fd, F_SETFL, flags & ~O_NONBLOCK) < 0)
		err(1, "fcntl(F_SETFL)");
}

std::string
af_unix::set_listen()
{
	struct sockaddr_un addr;
	std::memset(&addr, 0, sizeof(addr));
	addr.sun_family = AF_UNIX;

	char *viewer_sock;
	if ((viewer_sock = std::getenv("CITRUN_SOCKET")) != NULL)
		m_socket_path = viewer_sock;

	strlcpy(addr.sun_path, m_socket_path.c_str(), sizeof(addr.sun_path));

	if (bind(m_fd, (struct sockaddr *)&addr, sizeof(addr)))
		err(1, "bind");

	m_bound = 1;

	// Size 1024 backlog
	if (listen(m_fd, 1024))
		err(1, "listen");

	return m_socket_path;
}

af_unix *
af_unix::accept()
{
	int new_fd;
	struct sockaddr_un addr;
	socklen_t len = sizeof(struct sockaddr_un);

	// Namespace collision
	new_fd = ::accept(m_fd, (struct sockaddr *)&addr, &len);
	if (new_fd == -1) {
		if (errno != EWOULDBLOCK) {
			perror("accept");
		}
		return NULL;
	}

	return new af_unix(new_fd);
}

int
af_unix::write_all(uint8_t *buf, size_t bytes_total)
{
	int bytes_left = bytes_total;
	int bytes_wrote = 0;
	ssize_t n;

	while (bytes_left > 0) {
		n = write(m_fd, buf + bytes_wrote, bytes_left);

		if (n < 0)
			throw std::system_error(errno, std::system_category());

		bytes_wrote += n;
		bytes_left -= n;
	}

	return bytes_wrote;
}

int
af_unix::read_all(uint8_t *buf, size_t bytes_total)
{
	int bytes_left = bytes_total;
	int bytes_read = 0;
	ssize_t n;

	while (bytes_left > 0) {
		n = read(m_fd, buf + bytes_read, bytes_left);

		if (n == 0)
			throw std::runtime_error("read 0 bytes on socket");
		if (n < 0)
			err(1, "read()");

		bytes_read += n;
		bytes_left -= n;
	}

	return bytes_read;
}
