#ifndef AF_UNIX_H
#define AF_UNIX_H

#include <cstddef>
#include <cstdint>
#include <vector>

class af_unix {
public:
	af_unix();
	af_unix(int);
	~af_unix();

	void set_listen();
	af_unix *accept();

	int read_all(uint64_t &);
	int read_all(uint8_t *, size_t);

	int write_all(uint8_t *, size_t);
private:
	int fd;
};

#endif
