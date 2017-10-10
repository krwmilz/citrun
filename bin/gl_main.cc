#include <err.h>

#include "gl_main.h"

#if defined(__OpenBSD__)
#define FONT_PATH "/usr/X11R6/lib/X11/fonts/TTF/DejaVuSansMono.ttf"
#elif defined(__APPLE__)
#define FONT_PATH "/Library/Fonts/Andale Mono.ttf"
#elif defined(__gnu_linux__)
#define FONT_PATH "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf"
#elif defined(_WIN32)
#define FONT_PATH ""
#else
#error "Font string not configured."
#endif


citrun::gl_main::gl_main()
{
	static_vu = new View(st);
	font = new citrun::gl_font(FONT_PATH, st.get_atlas());
	static_vu->setup();

	glyphy_point_t top_left = { 0, 0 };
	buffer.move_to(&top_left);

	buffer.add_text("C It Run\n--------\n", *font, 3);

	buffer.add_text("Summary\n", *font, 2);
	buffer.add_text("No programs have been run yet.\n", *font, 1);
	buffer.add_text("Compile your program with the provided 'citrun_wrap' script.\n", *font, 1);
	buffer.add_text("Then run your program to see it run here.\n", *font, 1);
	buffer.add_text("\n", *font, 1);

	buffer.add_text("Controlling the Viewer\n", *font, 2);
	buffer.add_text("The viewer can be moved around with the h/j/k/l keys.\n", *font, 1);
	buffer.add_text("Use the +/- keys to zoom.", *font, 1);

	buffer.extents(NULL, &extents);
}

void
citrun::gl_main::tick()
{
	double x_offset = 0;

	for (std::string &file_name : m_pdir.scan()) {
		buffer.clear();
		drawables.emplace_back(file_name, *font, x_offset);
		x_offset += 50. ;
	}

	for (auto &i : drawables) {
		glyphy_extents_t t = i.get_extents();
		extents.max_x = std::max(extents.max_x, t.max_x);
		extents.max_y = std::max(extents.max_y, t.max_y);
		extents.min_x = std::min(extents.min_x, t.min_x);
		extents.min_y = std::min(extents.min_y, t.min_y);
	}

	// Set up view transforms
	static_vu->display(extents);

	buffer.draw();

	for (auto &i : drawables)
		i.display();
}
