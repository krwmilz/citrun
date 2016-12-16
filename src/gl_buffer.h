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

#ifndef GL_BUFFER_H
#define GL_BUFFER_H

#include <vector>

#include "demo-common.h"
#include "gl_font.h"
#include "demo-shader.h"


class GlBuffer
{
	unsigned int			 m_refcount;
	glyphy_point_t			 m_cursor;
	std::vector<glyph_vertex_t>	*m_vertices;
	glyphy_extents_t		 m_ink_extents;
	glyphy_extents_t		 m_logical_extents;
	bool				 m_dirty;
	GLuint				 m_buf_name;

public:
	GlBuffer();
	~GlBuffer();

	void		reference();
	void		clear();
	void		extents(glyphy_extents_t *, glyphy_extents_t *);
	void		move_to(const glyphy_point_t *);
	void		current_point(glyphy_point_t *);
	void		add_text(const char *, demo_font_t *, double);
	void		draw();
};

#endif // GL_BUFFER_H
