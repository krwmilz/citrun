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
	void read();
private:
	int fd;
	char buffer[4096];
};

#endif
