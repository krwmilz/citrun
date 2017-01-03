#include <string>
#include <vector>

#include "gl_buffer.h"
#include "gl_transunit.h"


//
// Owns an executing/executed instrumented processes shared memory file and gl
// buffer.
//
class GlProcessFile
{
	struct citrun_header	*m_header;
	std::string		 m_path;
	int			 m_fd;
	size_t			 m_size;
	GlBuffer		 m_glbuffer;

public:
	GlProcessFile(std::string const &, demo_font_t *);

	const GlTranslationUnit	*find_tu(std::string const &) const;
	bool			 is_alive() const;
	void			 display();
	glyphy_extents_t	 get_extents();

	std::vector<GlTranslationUnit> m_tus;
};
