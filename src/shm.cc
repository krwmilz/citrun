#include "shm.h"

#include <sys/mman.h>		// mmap
#include <sys/stat.h>		// S_IRUSR

#include <cassert>
#include <err.h>
#include <fcntl.h>		// O_RDONLY
#include <stdlib.h>		// getenv
#include <unistd.h>

Shm::Shm(std::string const &path) :
	m_path(path),
	m_fd(0),
	m_mem(NULL),
	m_pos(0)
{
	if ((m_fd = open(m_path.c_str(), O_RDONLY, S_IRUSR | S_IWUSR)) < 0)
		err(1, "open");

	struct stat sb;
	fstat(m_fd, &sb);

	if (sb.st_size > 1024 * 1024 * 1024)
		errx(1, "shared memory too large: %lli", sb.st_size);

	m_mem = (uint8_t *)mmap(NULL, sb.st_size, PROT_READ, MAP_SHARED, m_fd, 0);
	if (m_mem == MAP_FAILED)
		err(1, "mmap");

	m_size = sb.st_size;
}

void
Shm::next_page()
{
	int page_size = getpagesize();
	m_pos += page_size - (m_pos % page_size);
}

void
Shm::read_string(std::string &str)
{
	uint16_t len;

	memcpy(&len, m_mem + m_pos, sizeof(len));
	m_pos += sizeof(len);

	str.resize(len);
	memcpy(&str[0], m_mem + m_pos, len);
	m_pos += len;
}

void *
Shm::get_block(size_t inc)
{
	void *block = m_mem + m_pos;
	m_pos += inc;

	return block;
}

bool
Shm::at_end()
{
	assert(m_pos <= m_size);
	return (m_pos == m_size ? true : false);
}
