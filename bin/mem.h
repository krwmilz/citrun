#ifndef MEM_H
#define MEM_H

#include <string>		// std::string


namespace citrun {

//
// Class that handles operating system independent access to blocks of memory
// that are efficiently sized for the underlying system.
//
class mem
{
	size_t		 m_off;

	// Allocation size is system dependent.
	virtual size_t	 alloc_size() = 0;

protected:
	void		*m_base;
	size_t		 m_size;

public:
			 mem() : m_off(0) {};

	void		 increment(size_t size)
	{
		size_t page_mask;
		size_t rounded_size;

		// Round up to next allocation size.
		page_mask = alloc_size() - 1;
		rounded_size = (size + page_mask) & ~page_mask;

		m_off += rounded_size;
	}

	void		*get_ptr() { return (char *)m_base + m_off; }
	bool		 at_end() { return m_off >= m_size; }
	bool		 at_end_exactly() { return m_off == m_size; }

};

} // namespace citrun
#endif // MEM_H
