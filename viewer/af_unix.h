#ifndef AF_UNIX_H
#define AF_UNIX_H

#include <vector>

class af_unix_nonblock {
public:
	af_unix_nonblock();
	~af_unix_nonblock();
	void accept_one();
	void read();
private:
	int listen_fd;
	std::vector<int> connected_fds;
};

#endif
