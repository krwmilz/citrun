#include "shm.h"

#include <sys/mman.h>		// shm_open, mmap
#include <sys/stat.h>		// S_IRUSR

#include <cassert>
#include <err.h>
#include <fcntl.h>		// O_RDONLY
#include <unistd.h>

#define SHM_PATH "/tmp/citrun.shared"

shm::shm() :
	m_fd(0),
	m_mem(NULL),
	m_pos(0)
{
	if ((m_fd = shm_open(SHM_PATH, O_RDONLY, S_IRUSR | S_IWUSR)) < 0)
		err(1, "shm_open");

	struct stat sb;
	fstat(m_fd, &sb);

	if (sb.st_size > 1024 * 1024 * 1024)
		errx(1, "shared memory too large: %i", sb.st_size);

	m_mem = (uint8_t *)mmap(NULL, sb.st_size, PROT_READ, MAP_SHARED, m_fd, 0);
	if (m_mem == MAP_FAILED)
		err(1, "mmap");
	m_size = sb.st_size;
}

void
shm::read_string(std::string &str)
{
	uint16_t sz;
	read_all(&sz);

	if (sz > 1024)
		errx(1, "read_string: %i too long", sz);

	str.resize(sz);
	std::copy(m_mem + m_pos, m_mem + m_pos + sz, &str[0]);
	m_pos += sz;
}

void *
shm::get_block(size_t inc)
{
	void *block = m_mem + m_pos;
	m_pos += inc;

	return block;
}

bool
shm::at_end()
{
	assert(m_pos <= m_size);
	return (m_pos == m_size ? true : false);
}
