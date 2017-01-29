#include <string>		// std::string
#include <vector>		// std::vector

#include "gl_buffer.h"		// GlBuffer
#include "gl_transunit.h"	// GlTranslationUnit
#ifdef _WIN32
#include "mem_win32.h"
#else
#include "mem_unix.h"		// MemUnix
#endif


//
// Owns an executing/executed instrumented processes shared memory file and gl
// buffer.
//
class GlProcessFile
{
	struct citrun_header	*m_header;
	GlBuffer		 m_glbuffer;
#ifdef _WIN32
	MemWin32		 m_mem;
#else
	MemUnix			 m_mem;
#endif

public:
	GlProcessFile(std::string const &, demo_font_t *);

	const GlTranslationUnit	*find_tu(std::string const &) const;
	bool			 is_alive() const;
	void			 display();
	glyphy_extents_t	 get_extents();

	std::vector<GlTranslationUnit> m_tus;
};
