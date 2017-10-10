#include <string>		// std::string
#include <vector>		// std::vector

#include "gl_font.h"		// citrun::gl_font
#include "gl_buffer.h"		// citrun::gl_buffer
#include "gl_transunit.h"	// citrun::gl_transunit
#ifdef _WIN32
#include "mem_win32.h"
#else
#include "mem_unix.h"		// citrun::mem_unix
#endif


namespace citrun {

//
// Owns an executing/executed instrumented processes shared memory file and gl
// buffer.
//
class gl_procfile
{
	struct citrun_header	*m_header;
	citrun::gl_buffer	 m_glbuffer;
#ifdef _WIN32
	MemWin32		 m_mem;
#else
	citrun::mem_unix	 m_mem;
#endif

public:
	gl_procfile(std::string const&, citrun::gl_font &, double const&);

	const citrun::gl_transunit *find_tu(std::string const &) const;
	bool			 is_alive() const;
	void			 display();
	glyphy_extents_t	 get_extents();

	std::vector<citrun::gl_transunit> m_tus;
};

} // namespace citrun
