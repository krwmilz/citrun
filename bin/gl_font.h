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

#ifndef GL_FONT_H
#define GL_FONT_H

#include <unordered_map>

#include "demo-common.h"
#include "gl_atlas.h"

#include <ft2build.h>
#include FT_FREETYPE_H


namespace citrun {

typedef struct {
	glyphy_extents_t extents;
	double		advance;
	glyphy_bool_t	is_empty; /* has no outline; eg. space; don't draw it */
	unsigned int	nominal_w;
	unsigned int	nominal_h;
	unsigned int	atlas_x;
	unsigned int	atlas_y;
} glyph_info_t;

class gl_font {
	FT_Library	 ft_library;
	FT_Face		 face;

	std::unordered_map<unsigned int, glyph_info_t> glyph_cache;

	/* stats */
	unsigned int	 num_glyphs;
	double		 sum_error;
	unsigned int	 sum_endpoints;
	double		 sum_fetch;
	unsigned int	 sum_bytes;

	citrun::gl_atlas &atlas;
	glyphy_arc_accumulator_t *acc;

	void		 _upload_glyph(unsigned int, glyph_info_t *);
	void		 encode_ft_glyph(unsigned int,
				double,
				glyphy_rgba_t *,
				unsigned int,
				unsigned int *,
				unsigned int *,
				unsigned int *,
				glyphy_extents_t *,
				double *);
public:
			 gl_font(std::string const&, citrun::gl_atlas &);
			~gl_font();

	FT_Face		 get_face() const;
	citrun::gl_atlas &get_atlas();
	void		 lookup_glyph(unsigned int, glyph_info_t *);
	void		 print_stats();
};

} // namespace citrun
#endif /* GL_FONT_H */
