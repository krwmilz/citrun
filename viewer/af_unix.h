#ifndef AF_UNIX_H
#define AF_UNIX_H

#include <vector>

class af_unix_nonblock {
public:
	af_unix_nonblock();
	af_unix_nonblock(int);
	~af_unix_nonblock();

	void set_listen();
	af_unix_nonblock *accept();

	int read_block(uint64_t &);
	int read_block(uint8_t *, size_t);

	int read_nonblock(uint8_t *, size_t);
	int write_all(uint8_t *, size_t);
private:
	int fd;
};

#endif
