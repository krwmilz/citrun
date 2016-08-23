#ifndef SHM_H
#define SHM_H

#include <string.h>
#include <string>
#include <unistd.h>		// getpagesize

class Shm {
public:
	Shm(std::string const &);

	template<typename T>
	void read_all(T *buf)
	{
		memcpy(buf, m_mem + m_pos, sizeof(T));
		m_pos += sizeof(T);
	};

	void next_page()
	{
		int page_size = getpagesize();
		m_pos += page_size - (m_pos % page_size);
	}

	void read_cstring(const char **);
	void *get_block(size_t);
	bool at_end();

private:
	std::string	 m_path;
	int		 m_fd;
	uint8_t		*m_mem;
	size_t		 m_pos;
	size_t		 m_size;
};

#endif // SHM_H
