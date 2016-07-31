#ifndef AF_UNIX_H
#define AF_UNIX_H

#include <vector>

class af_unix {
public:
	af_unix();
	af_unix(int);
	~af_unix();

	std::string	 set_listen();
	void		 set_block();
	void		 set_nonblock();
	af_unix		*accept();

	template<typename T>
	int read_all(T &buf)
	{
		return read_all((uint8_t *)&buf, sizeof(T));
	};

	int read_all(uint8_t *, size_t);
	int write_all(uint8_t *, size_t);
private:
	int		m_fd;
	int		m_bound;
	std::string	m_socket_path;
};

#endif
