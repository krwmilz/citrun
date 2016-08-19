#ifndef SHM_H
#define SHM_H

#include <string.h>
#include <string>

class shm {
public:
	shm();

	template<typename T>
	void read_all(T *buf)
	{
		memcpy(buf, m_mem + m_pos, sizeof(T));
		m_pos += sizeof(T);
	};

	void read_pos(uint8_t *bit)
	{
		*bit = m_mem[m_pos];
	}

	void read_cstring(const char **);
	void *get_block(size_t);
	bool at_end();


	//void read_string(std::string &);
private:
	int		 m_fd;
	uint8_t		*m_mem;
	size_t		 m_pos;
	off_t		 m_size;
};

#endif // SHM_H
