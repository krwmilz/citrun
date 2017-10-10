//
// Copyright (c) 2016 Kyle Milz <kyle@0x30.net>
//
// Permission to use, copy, modify, and distribute this software for any
// purpose with or without fee is hereby granted, provided that the above
// copyright notice and this permission notice appear in all copies.
//
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
// WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
// ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
// WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
// ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
// OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
//
#include <cassert>		// assert
#include <csignal>		// kill
#include <cstring>		// std::strncmp
#include <sstream>		// std::stringstream

#include "lib.h"		// citrun_major, struct citrun_{node,header}
#include "gl_procfile.h"	// citrun::gl_procfile


//
// Take a filesystem path and memory map its contents. Map at least a header
// structure on top of it.
//
citrun::gl_procfile::gl_procfile(std::string const &path, citrun::gl_font &font, double const &x_off) :
	m_mem(path)
{
	// Header is always at offset 0.
	m_header = static_cast<struct citrun_header *>(m_mem.get_ptr());
	m_mem.increment(sizeof(struct citrun_header));

	assert(std::strncmp(m_header->magic, "ctrn", 4) == 0);
	assert(m_header->major == citrun_major);

	glyphy_point_t orig_pos = { x_off, 0 };
	m_glbuffer.move_to(&orig_pos);

	std::stringstream maj;
	maj << "Name:              '" << m_header->progname << "'" << std::endl;
	maj << "Translation Units: " << m_header->units << std::endl;
	maj << "Lines of code:     " << m_header->loc << std::endl;
	m_glbuffer.add_text(maj.str().c_str(), font, 3);

	std::stringstream min;
	min << "Working directory: " << m_header->cwd << std::endl;
	min << "Instrumented with: v" << m_header->major << "." << m_header->minor << std::endl;
	m_glbuffer.add_text(min.str().c_str(), font, 2);

	glyphy_point_t draw_pos;
	m_glbuffer.current_point(&draw_pos);

	while (!m_mem.at_end()) {
		m_tus.emplace_back(m_mem, font, draw_pos);
		draw_pos.x += 80;
	}

	// Make sure internal increment in TranslationUnit works as intended.
	assert(m_mem.at_end_exactly());
}

//
// Checks if the pid given by the runtime is alive. Prone to race conditions.
//
bool
citrun::gl_procfile::is_alive() const
{
	return kill(m_header->pids[0], 0) == 0;
}

const citrun::gl_transunit *
citrun::gl_procfile::find_tu(std::string const &srcname) const
{
	for (auto &i : m_tus)
		if (srcname == i.comp_file_path())
			return &i;
	return NULL;
}

void
citrun::gl_procfile::display()
{
	m_glbuffer.draw();

	for (auto &t : m_tus)
		t.display();
}

glyphy_extents_t
citrun::gl_procfile::get_extents()
{
	glyphy_extents_t extents;
	m_glbuffer.extents(NULL, &extents);

	for (auto &i : m_tus) {
		glyphy_extents_t t = i.get_extents();
		extents.max_x = std::max(extents.max_x, t.max_x);
		extents.max_y = std::max(extents.max_y, t.max_y);
		extents.min_x = std::min(extents.min_x, t.min_x);
		extents.min_y = std::min(extents.min_y, t.min_y);
	}

	return extents;
}
