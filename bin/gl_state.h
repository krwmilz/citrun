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
#ifndef DEMO_GLSTATE_H
#define DEMO_GLSTATE_H

#include "demo-common.h"
#include "demo-atlas.h"
#include "demo-shader.h"


namespace citrun {

class gl_state {
	GLuint		 program;
	demo_atlas_t	*atlas;

	/* Uniforms */
	double		 u_debug;
	double		 u_contrast;
	double		 u_gamma_adjust;
	double		 u_outline;
	double		 u_outline_thickness;
	double		 u_boldness;
public:
			 gl_state();
			~gl_state();

	void		 setup();
	demo_atlas_t	*get_atlas();
	void		 scale_gamma_adjust(double);
	void		 scale_contrast(double);
	void		 toggle_debug();
	void		 set_matrix(float[16]);
	void		 toggle_outline();
	void		 scale_outline_thickness(double);
	void		 adjust_boldness(double);
};

} // namespace citrun

#endif /* DEMO_GLSTATE_H */
