//
// Copyright (c) 2016, 2017 Kyle Milz <kyle@0x30.net>
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
#include <sys/stat.h>

#include <cassert>		// assert
#include <cstdlib>		// std::getenv
#include <cstring>		// std::memcpy, std::strncmp
#include <csignal>		// kill
#include <err.h>
#include <fstream>		// std::ifstream
#include <iostream>		// std::cerr
#include <sstream>		// std::stringstream

#include "lib.h"		// struct citrun_node
#include "gl_runtime.h"		// citrun::gl_transunit, citrun::gl_procfile


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

//
// citrun::gl_procfile
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


//
// citrun::process_dir
//
citrun::process_dir::process_dir()
{
	if ((m_procdir = std::getenv("CITRUN_PROCDIR")) == NULL)
		m_procdir = "/tmp/citrun/";

	if ((m_dirp = opendir(m_procdir)) == NULL) {
		if (errno != ENOENT)
			err(1, "opendir '%s'", m_procdir);

		// Create if there was no such file or directory.
		mkdir(m_procdir, S_IRWXU);
		if ((m_dirp = opendir(m_procdir)) == NULL)
			err(1, "opendir '%s'", m_procdir);
	}
}

std::vector<std::string>
citrun::process_dir::scan()
{
	std::vector<std::string>	 new_files;
	struct dirent			*dp;

	rewinddir(m_dirp);
	while ((dp = readdir(m_dirp)) != NULL) {

		if (std::strcmp(dp->d_name, ".") == 0 ||
		    std::strcmp(dp->d_name, "..") == 0)
			continue;

		std::string p(m_procdir);
		p.append(dp->d_name);

		if (m_known_files.find(p) != m_known_files.end())
			// We already know this file.
			continue;

		m_known_files.insert(p);
		new_files.push_back(p);
	}

	return new_files;
}
