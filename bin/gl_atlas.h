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
 * Google Author(s): Behdad Esfahbod, Maysum Panju
 */
#ifndef DEMO_ATLAS_H
#define DEMO_ATLAS_H

#include "demo-common.h"


namespace citrun {

class gl_atlas {
	GLuint		 tex_unit;
	GLuint		 tex_name;
	GLuint		 tex_w;
	GLuint		 tex_h;
	GLuint		 item_w;
	GLuint		 item_h_q; /* height quantum */
	GLuint		 cursor_x;
	GLuint		 cursor_y;

public:
			 gl_atlas(unsigned int, unsigned int, unsigned int, unsigned int);
			~gl_atlas();

	void		 alloc(glyphy_rgba_t *, unsigned int, unsigned int *, unsigned int *);
	void		 bind_texture();
	void		 set_uniforms();
};

} // namespace citrun

#endif /* DEMO_ATLAS_H */
