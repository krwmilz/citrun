#include <vector>

#include "gl_buffer.h"		// citrun::gl_buffer
#include "gl_font.h"		// citrun::gl_font
#include "gl_procfile.h"	// citrun::gl_procfile
#include "gl_view.h"
#include "process_dir.h"	// citrun::process_dir


namespace citrun {

class gl_main {
	citrun::gl_buffer	 buffer;
	citrun::gl_font		*font;
	citrun::process_dir	 m_pdir;

	std::vector<citrun::gl_procfile> drawables;
	demo_glstate_t		*st;
	glyphy_extents_t	 extents;
	View			*static_vu;
public:
	gl_main();
	void tick();
	View *get_static_vu() { return static_vu; };
};

} // namespace citrun
