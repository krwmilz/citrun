#include <string>		// std::string
#include <vector>		// std::vector

#include "gl_buffer.h"		// GlBuffer
#include "mem.h"		// Mem


//
// Owns a few pages of shared memory and a gl buffer.
//
class GlTranslationUnit
{
	struct citrun_node	*m_node;
	uint64_t		*m_data;
	std::vector<uint64_t>	 m_data_buffer;
	GlBuffer		 m_glbuffer;

public:
	GlTranslationUnit(Mem &, demo_font_t *, glyphy_point_t &);

	std::string		 comp_file_path() const;
	unsigned int		 num_lines() const;
	void			 save_executions();
	void			 display();
	glyphy_extents_t	 get_extents();
};
