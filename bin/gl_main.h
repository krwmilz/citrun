#include <vector>

#include "gl_buffer.h"		// citrun::gl_buffer
#include "gl_font.h"		// citrun::gl_font
#include "gl_runtime.h"		// citrun::gl_procfile, citrun::process_dir
#include "gl_state.h"		// citrun::gl_state
#include "gl_view.h"


namespace citrun {

class gl_main {
	citrun::gl_buffer	 buffer;
	citrun::gl_font		*font;
	citrun::process_dir	 m_pdir;
	citrun::gl_state	 st;

	std::vector<citrun::gl_procfile> drawables;
	glyphy_extents_t	 extents;
	View			*static_vu;
public:
	gl_main();
	void tick();
	View *get_static_vu() { return static_vu; };
};

} // namespace citrun
