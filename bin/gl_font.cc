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
#include <assert.h>
#include <err.h>
#include <math.h>
#include <string>		// std::string
#include <vector>		// std::vector

#include "gl_font.h"
#include "glyphy/glyphy-freetype.h"


citrun::gl_font::gl_font(std::string const &font_path, demo_atlas_t *at) :
	face(NULL),
	num_glyphs(0),
	sum_error(0),
	sum_endpoints(0),
	sum_fetch(0),
	sum_bytes(0),
	atlas(demo_atlas_reference(at)),
	acc(glyphy_arc_accumulator_create())
{
	FT_Init_FreeType(&ft_library);
	FT_New_Face(ft_library, font_path.c_str(), /* face_index */ 0, &face);
}

citrun::gl_font::~gl_font()
{
	glyphy_arc_accumulator_destroy(acc);
	demo_atlas_destroy(atlas);
}

FT_Face
citrun::gl_font::get_face() const
{
	return face;
}

demo_atlas_t *
citrun::gl_font::get_atlas()
{
	return atlas;
}


static glyphy_bool_t
accumulate_endpoint(glyphy_arc_endpoint_t *endpoint,
		     std::vector<glyphy_arc_endpoint_t> *endpoints)
{
	endpoints->push_back (*endpoint);
	return true;
}

void
citrun::gl_font::encode_ft_glyph(unsigned int      glyph_index,
		 double            tolerance_per_em,
		 glyphy_rgba_t    *buffer,
		 unsigned int      buffer_len,
		 unsigned int     *output_len,
		 unsigned int     *nominal_width,
		 unsigned int     *nominal_height,
		 glyphy_extents_t *extents,
		 double           *advance)
{
/* Used for testing only */
#define SCALE  (1. * (1 << 0))

  if (FT_Err_Ok != FT_Load_Glyph (face,
				  glyph_index,
				  FT_LOAD_NO_BITMAP |
				  FT_LOAD_NO_HINTING |
				  FT_LOAD_NO_AUTOHINT |
				  FT_LOAD_NO_SCALE |
				  FT_LOAD_LINEAR_DESIGN |
				  FT_LOAD_IGNORE_TRANSFORM))
    errx(1, "Failed loading FreeType glyph");

  if (face->glyph->format != FT_GLYPH_FORMAT_OUTLINE)
    errx(1, "FreeType loaded glyph format is not outline");

  unsigned int upem = face->units_per_EM;
  double tolerance = upem * tolerance_per_em; /* in font design units */
  double faraway = double (upem) / (MIN_FONT_SIZE * M_SQRT2);
  std::vector<glyphy_arc_endpoint_t> endpoints;

  glyphy_arc_accumulator_reset (acc);
  glyphy_arc_accumulator_set_tolerance (acc, tolerance);
  glyphy_arc_accumulator_set_callback (acc,
				       (glyphy_arc_endpoint_accumulator_callback_t) accumulate_endpoint,
				       &endpoints);

  if (FT_Err_Ok != glyphy_freetype(outline_decompose) (&face->glyph->outline, acc))
    errx(1, "Failed converting glyph outline to arcs");

  assert (glyphy_arc_accumulator_get_error (acc) <= tolerance);

  if (endpoints.size ())
  {
#if 0
    /* Technically speaking, we want the following code,
     * however, crappy fonts have crappy flags.  So we just
     * fixup unconditionally... */
    if (face->glyph->outline.flags & FT_OUTLINE_EVEN_ODD_FILL)
      glyphy_outline_winding_from_even_odd (&endpoints[0], endpoints.size (), false);
    else if (face->glyph->outline.flags & FT_OUTLINE_REVERSE_FILL)
      glyphy_outline_reverse (&endpoints[0], endpoints.size ());
#else
    glyphy_outline_winding_from_even_odd (&endpoints[0], endpoints.size (), false);
#endif
  }

  if (SCALE != 1.)
    for (unsigned int i = 0; i < endpoints.size (); i++)
    {
      endpoints[i].p.x /= SCALE;
      endpoints[i].p.y /= SCALE;
    }

  double avg_fetch_achieved;
  if (!glyphy_arc_list_encode_blob (endpoints.size () ? &endpoints[0] : NULL, endpoints.size (),
				    buffer,
				    buffer_len,
				    faraway / SCALE,
				    4, /* UNUSED */
				    &avg_fetch_achieved,
				    output_len,
				    nominal_width,
				    nominal_height,
				    extents))
    errx(1, "Failed encoding arcs");

  glyphy_extents_scale (extents, 1. / upem, 1. / upem);
  glyphy_extents_scale (extents, SCALE, SCALE);

  *advance = face->glyph->metrics.horiAdvance / (double) upem;

  if (0)
    LOGI ("gid%3u: endpoints%3d; err%3g%%; tex fetch%4.1f; mem%4.1fkb\n",
	  glyph_index,
	  (unsigned int) glyphy_arc_accumulator_get_num_endpoints (acc),
	  round (100 * glyphy_arc_accumulator_get_error (acc) / tolerance),
	  avg_fetch_achieved,
	  (*output_len * sizeof (glyphy_rgba_t)) / 1024.);

  num_glyphs++;
  sum_error += glyphy_arc_accumulator_get_error (acc) / tolerance;
  sum_endpoints += glyphy_arc_accumulator_get_num_endpoints (acc);
  sum_fetch += avg_fetch_achieved;
  sum_bytes += (*output_len * sizeof (glyphy_rgba_t));
}

void
citrun::gl_font::_upload_glyph(unsigned int glyph_index,
		glyph_info_t *glyph_info)
{
	glyphy_rgba_t buffer[4096 * 16];
	unsigned int output_len;

	encode_ft_glyph(glyph_index,
			TOLERANCE,
			buffer, ARRAY_LEN (buffer),
			&output_len,
			&glyph_info->nominal_w,
			&glyph_info->nominal_h,
			&glyph_info->extents,
			&glyph_info->advance);

	glyph_info->is_empty = glyphy_extents_is_empty (&glyph_info->extents);
	if (!glyph_info->is_empty)
		demo_atlas_alloc (atlas, buffer, output_len,
				&glyph_info->atlas_x, &glyph_info->atlas_y);
}

void
citrun::gl_font::lookup_glyph(unsigned int glyph_index,
			glyph_info_t *glyph_info)
{
	if (glyph_cache.find(glyph_index) == glyph_cache.end()) {
		_upload_glyph(glyph_index, glyph_info);
		glyph_cache[glyph_index] = *glyph_info;
	} else
		*glyph_info = glyph_cache[glyph_index];
}

void
citrun::gl_font::print_stats()
{
	LOGI("%3d glyphs; avg num endpoints%6.2f; avg error%5.1f%%; avg tex fetch%5.2f; avg %5.2fkb per glyph\n",
		num_glyphs,
		(double) sum_endpoints / num_glyphs,
		100. * sum_error / num_glyphs,
		sum_fetch / num_glyphs,
		sum_bytes / 1024. / num_glyphs);
}
