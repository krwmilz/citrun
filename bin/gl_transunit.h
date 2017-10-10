#include <string>		// std::string
#include <vector>		// std::vector

#include "gl_buffer.h"		// citrun::gl_buffer
#include "gl_font.h"		// citrun::gl_font
#include "mem.h"		// citrun::mem


namespace citrun {

//
// Owns a few pages of shared memory and a gl buffer.
//
class gl_transunit
{
	struct citrun_node	*m_node;
	uint64_t		*m_data;
	std::vector<uint64_t>	 m_data_buffer;
	citrun::gl_buffer	 m_glbuffer;

public:
	gl_transunit(citrun::mem &, citrun::gl_font &, glyphy_point_t &);

	std::string		 comp_file_path() const;
	unsigned int		 num_lines() const;
	void			 save_executions();
	void			 display();
	glyphy_extents_t	 get_extents();
};

} // namespace citrun
