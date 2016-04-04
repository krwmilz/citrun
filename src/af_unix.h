#ifndef AF_UNIX_H
#define AF_UNIX_H

#include <unistd.h>		// read
#include <vector>

class af_unix {
public:
	af_unix();
	af_unix(int);
	~af_unix();

	void set_listen();
	af_unix *accept();

	// Makes sure reads don't overflow or underflow types
	template<typename T>
	int read_all(T &buf)
	{
		int bytes_left = sizeof(T);
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
	};

	int read_all(uint8_t *, size_t);
	int write_all(uint8_t *, size_t);
private:
	int fd;
};

#endif
