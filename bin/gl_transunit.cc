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
#include <cstring>		// std::memcpy
#include <fstream>		// std::ifstream
#include <iostream>		// std::cerr
#include <sstream>		// std::stringstream

#include "lib.h"		// struct citrun_node
#include "gl_transunit.h"	// citrun::gl_transunit


//
// Take a pointer to a shared memory region and map data structures on top.
// Automatically increments the pointer once we know how big this region is.
//
citrun::gl_transunit::gl_transunit(citrun::mem &m_mem, citrun::gl_font &font,
		glyphy_point_t &draw_pos) :
	m_node(static_cast<struct citrun_node *>(m_mem.get_ptr())),
	m_data((unsigned long long *)(m_node + 1)),
	m_data_buffer(m_node->size)
{
	unsigned int	 size;

	// Total size is node size plus live execution data size.
	size = sizeof(struct citrun_node);
	size += m_node->size * sizeof(unsigned long long);
	m_mem.increment(size);

	m_glbuffer.move_to(&draw_pos);

	std::stringstream tu_info;
	tu_info << "Source file:   " << m_node->comp_file_path << std::endl;
	tu_info << "Lines of code: " << m_node->size << std::endl;
	m_glbuffer.add_text(tu_info.str().c_str(), font, 2);

	glyphy_point_t cur_pos;
	m_glbuffer.current_point(&cur_pos);
	cur_pos.x = draw_pos.x;
	m_glbuffer.move_to(&cur_pos);

	std::ifstream file_stream(m_node->abs_file_path);
	if (file_stream.is_open() == 0) {
		std::cerr << "ifstream.open: " << m_node->abs_file_path << std::endl;
		return;
	}

	std::string line;
	unsigned int i;
	for (i = 1; std::getline(file_stream, line); ++i) {
		m_glbuffer.add_text(line.c_str(), font, 1);

		m_glbuffer.current_point(&cur_pos);
		cur_pos.x = draw_pos.x;
		m_glbuffer.move_to(&cur_pos);
	}

	if (i != m_node->size)
		std::cerr << m_node->abs_file_path << " size mismatch: "
			<< i << " vs " << m_node->size << std::endl;
}

//
// Returns number of lines that citrun_inst processed (whole source file
// ideally)
//
unsigned int
citrun::gl_transunit::num_lines() const
{
	return m_node->size;
}

//
// Returns the source file path as it was passed to the compiler.
//
std::string
citrun::gl_transunit::comp_file_path() const
{
	return std::string(m_node->comp_file_path);
}

glyphy_extents_t
citrun::gl_transunit::get_extents()
{
	glyphy_extents_t extents;
	m_glbuffer.extents(NULL, &extents);

	return extents;
}

//
// Copy live executions to secondary buffer. Used for computing deltas later.
//
void
citrun::gl_transunit::save_executions()
{
	std::memcpy(&m_data_buffer[0], m_data, m_node->size * sizeof(unsigned long long));
}

void
citrun::gl_transunit::display()
{
	m_glbuffer.draw();
}
