/*
 * Copyright 2012 Google, Inc. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * Google Author(s): Behdad Esfahbod
 */

#include "gl_buffer.h"


citrun::gl_buffer::gl_buffer() : m_refcount(1), m_cursor({0, 0})
{
	glGenBuffers(1, &m_buf_name);
	clear();
}

#if 0
gl_buffer::~gl_buffer()
{
	//if (!buffer || --buffer->refcount)
	//	return;

	glDeleteBuffers(1, &m_buf_name);
}
#endif

void
citrun::gl_buffer::reference()
{
	m_refcount++;
}

void
citrun::gl_buffer::clear()
{
	m_vertices.clear();
	glyphy_extents_clear(&m_ink_extents);
	glyphy_extents_clear(&m_logical_extents);
	m_dirty = true;
}

void
citrun::gl_buffer::extents(glyphy_extents_t *ink, glyphy_extents_t *logical)
{
	if (ink)
		*ink = m_ink_extents;
	if (logical)
		*logical = m_logical_extents;
}

void
citrun::gl_buffer::move_to(const glyphy_point_t *p)
{
	m_cursor = *p;
}

void
citrun::gl_buffer::current_point(glyphy_point_t *p)
{
	*p = m_cursor;
}

void
citrun::gl_buffer::add_text(const char *utf8, citrun::gl_font &font, double font_size)
{
	FT_Face face = font.get_face();
	glyphy_point_t top_left = m_cursor;
	m_cursor.y += font_size /* * font->ascent */;
	unsigned int unicode;
	unsigned int col = 0;

	for (const unsigned char *p = (const unsigned char *) utf8; *p; p++) {
		if (*p < 128) {
			unicode = *p;
		} else {
			unsigned int j;
			if (*p < 0xE0) {
				unicode = *p & ~0xE0;
				j = 1;
			} else if (*p < 0xF0) {
				unicode = *p & ~0xF0;
				j = 2;
			} else {
				unicode = *p & ~0xF8;
				j = 3;
				continue;
			}
			p++;
			for (; j && *p; j--, p++)
				unicode = (unicode << 6) | (*p & ~0xC0);
			p--;
		}

		if (unicode == '\n') {
			m_cursor.y += font_size;
			m_cursor.x = top_left.x;
			col = 0;
			continue;
		}

		unsigned int glyph_index = FT_Get_Char_Index(face, unicode);
		glyph_info_t gi;
		font.lookup_glyph(glyph_index, &gi);

		/* Let tab operate like it does in editors, 8 spaces. */
		if (unicode == '\t') {
			int nspaces = 8 - (col % 8);
			m_cursor.x += font_size * gi.advance * nspaces;
			col += nspaces;
			continue;
		}

		/* Update ink extents */
		glyphy_extents_t m_ink_extents;
		shader.add_glyph_vertices(m_cursor, font_size, &gi, &m_vertices, &m_ink_extents);
		glyphy_extents_extend(&m_ink_extents, &m_ink_extents);

		/* Update logical extents */
		glyphy_point_t corner;
		corner.x = m_cursor.x;
		corner.y = m_cursor.y - font_size;
		glyphy_extents_add(&m_logical_extents, &corner);
		corner.x = m_cursor.x + font_size * gi.advance;
		corner.y = m_cursor.y;
		glyphy_extents_add(&m_logical_extents, &corner);

		m_cursor.x += font_size * gi.advance;

		/* Hack; Not all characters are a single column wide. */
		col++;
	}

	m_dirty = true;
}

void
citrun::gl_buffer::draw()
{
	GLint program;
	glGetIntegerv(GL_CURRENT_PROGRAM, &program);
	GLuint a_glyph_vertex_loc = glGetAttribLocation(program, "a_glyph_vertex");
	glBindBuffer(GL_ARRAY_BUFFER, m_buf_name);
	if (m_dirty) {
		glBufferData(GL_ARRAY_BUFFER,  sizeof (glyph_vertex_t) * m_vertices.size(), (const char *) &(m_vertices)[0], GL_STATIC_DRAW);
		m_dirty = false;
	}
	glEnableVertexAttribArray (a_glyph_vertex_loc);
	glVertexAttribPointer (a_glyph_vertex_loc, 4, GL_FLOAT, GL_FALSE, sizeof (glyph_vertex_t), 0);
	glDrawArrays (GL_TRIANGLES, 0, m_vertices.size());
	glDisableVertexAttribArray (a_glyph_vertex_loc);
}
