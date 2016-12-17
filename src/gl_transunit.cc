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
#include <cstring>		// memcpy
#include <err.h>
#include <fstream>
#include <iostream>
#include <unistd.h>		// getpagesize

#include "gl_transunit.h"
#include "lib.h"		// struct citrun_node


//
// Take a pointer to a shared memory region and map data structures on top.
// Automatically increments the pointer once we know how big this region is.
//
GlTranslationUnit::GlTranslationUnit(void* &mem, demo_font_t *font,
		glyphy_point_t &cur_pos) :
	m_node(static_cast<struct citrun_node *>(mem)),
	m_data((unsigned long long *)(m_node + 1)),
	m_data_buffer(new uint64_t[m_node->size]())
{
	unsigned int	 size, page_mask;

	// Total size is node size plus live execution data size.
	size = sizeof(struct citrun_node);
	size += m_node->size * sizeof(unsigned long long);

	// Increment passed in pointer to next page.
	page_mask = getpagesize() - 1;
	mem = (char *)mem + ((size + page_mask) & ~page_mask);

	glyphy_point_t next_pos = cur_pos;
	next_pos.x += 80;
	m_glbuffer.move_to(&cur_pos);

	m_glbuffer.add_text(m_node->comp_file_path, font, 1);

	std::ifstream file_stream(m_node->abs_file_path);
	if (file_stream.is_open() == 0) {
		warnx("ifstream.open(%s)", m_node->abs_file_path);
		return;
	}

	std::string line;
	unsigned int i;
	for (i = 0; std::getline(file_stream, line); ++i) {
		m_glbuffer.current_point(&cur_pos);
		cur_pos.x = 0;

		m_glbuffer.move_to(&cur_pos);
		//m_glbuffer.add_text(line.c_str(), font, 1);
	}

	if (i != m_node->size)
		warnx("%s size mismatch: %u vs %u", m_node->abs_file_path, i,
			m_node->size);
}

//
// Returns number of lines that citrun-inst processed (whole source file
// ideally)
//
unsigned int
GlTranslationUnit::num_lines() const
{
	return m_node->size;
}

//
// Returns the source file path as it was passed to the compiler.
//
std::string
GlTranslationUnit::comp_file_path() const
{
	return std::string(m_node->comp_file_path);
}

glyphy_extents_t
GlTranslationUnit::get_extents()
{
	glyphy_extents_t extents;
	m_glbuffer.extents(NULL, &extents);

	return extents;
}

//
// Copy live executions to secondary buffer. Used for computing deltas later.
//
void
GlTranslationUnit::save_executions()
{
	std::memcpy(m_data_buffer, m_data, m_node->size * sizeof(unsigned long long));
}

void
GlTranslationUnit::display()
{
	m_glbuffer.draw();
}
