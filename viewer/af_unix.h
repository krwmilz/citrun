#ifndef AF_UNIX_H
#define AF_UNIX_H

#include <vector>

class af_unix_nonblock {
public:
	af_unix_nonblock();
	af_unix_nonblock(int);
	~af_unix_nonblock();

	af_unix_nonblock *accept();
	void set_listen();
	int read_all(uint8_t *, size_t);
	int write_all(uint8_t *, size_t);
private:
	int fd;
};

#endif
