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
 * Google Author(s): Behdad Esfahbod, Maysum Panju, Wojciech Baranowski
 */
#include "gl_state.h"		// citrun::gl_state


citrun::gl_state::gl_state() :
	program(demo_shader_create_program()),
	atlas(demo_atlas_create(2048, 1024, 64, 8)),
	u_debug(false),
	u_contrast(1.0),
	u_gamma_adjust(1.0),
	u_outline(false),
	u_outline_thickness(1.0),
	u_boldness(0.)
{
	TRACE();
}

citrun::gl_state::~gl_state()
{
	demo_atlas_destroy(atlas);
	glDeleteProgram(program);
}

static void
set_uniform(GLuint program, const char *name, double *p, double value)
{
	*p = value;
	glUniform1f(glGetUniformLocation(program, name), value);
	LOGI("Setting %s to %g\n", name + 2, value);
}

#define SET_UNIFORM(name, value) set_uniform (program, #name, &name, value)

void
citrun::gl_state::setup()
{
	glUseProgram(program);

	demo_atlas_set_uniforms(atlas);

	SET_UNIFORM(u_debug, u_debug);
	SET_UNIFORM(u_contrast, u_contrast);
	SET_UNIFORM(u_gamma_adjust, u_gamma_adjust);
	SET_UNIFORM(u_outline, u_outline);
	SET_UNIFORM(u_outline_thickness, u_outline_thickness);
	SET_UNIFORM(u_boldness, u_boldness);

	glEnable(GL_BLEND);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
}

demo_atlas_t *
citrun::gl_state::get_atlas()
{
	return atlas;
}

void
citrun::gl_state::scale_gamma_adjust(double factor)
{
	SET_UNIFORM(u_gamma_adjust, clamp(u_gamma_adjust * factor, .1, 10.));
}

void
citrun::gl_state::scale_contrast(double factor)
{
	SET_UNIFORM(u_contrast, clamp(u_contrast * factor, .1, 10.));
}

void
citrun::gl_state::toggle_debug()
{
	SET_UNIFORM(u_debug, 1 - u_debug);
}

void
citrun::gl_state::set_matrix(float mat[16])
{
	glUniformMatrix4fv(glGetUniformLocation(program, "u_matViewProjection"), 1, GL_FALSE, mat);
}

void
citrun::gl_state::toggle_outline()
{
	SET_UNIFORM(u_outline, 1 - u_outline);
}

void
citrun::gl_state::scale_outline_thickness(double factor)
{
	SET_UNIFORM(u_outline_thickness, clamp(u_outline_thickness * factor, .5, 3.));
}

void
citrun::gl_state::adjust_boldness(double adjustment)
{
	SET_UNIFORM (u_boldness, clamp (u_boldness + adjustment, -.2, .7));
}
