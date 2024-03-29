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
#include <assert.h>
#include <GL/glew.h>

#include "gl_view.h"

extern "C" {
#include "matrix4x4.h"
}


View::View(citrun::gl_state &st) :
	refcount(1),
	st(st),
	fullscreen(false)
{
	TRACE();

	reset();
}

View::~View()
{
	assert (refcount == 1);
}


#define ANIMATION_SPEED 1. /* Default speed, in radians second. */
void
View::reset()
{
	perspective = 4;
	scale_ = 1;
	translate_.x = translate_.y = 0;
	// trackball (quat , 0.0, 0.0, 0.0, 0.0);
	// vset (rot_axis, 0., 0., 1.);
	rot_speed = ANIMATION_SPEED / 1000.;
}

void
View::scale_gamma_adjust(double factor)
{
	st.scale_gamma_adjust(factor);
}

void
View::scale_contrast(double factor)
{
	st.scale_contrast(factor);
}

void
View::scale_perspective(double factor)
{
	perspective = clamp(perspective * factor, .01, 100.);
}

void
View::toggle_outline()
{
	st.toggle_outline();
}

void
View::scale_outline_thickness(double factor)
{
	st.scale_outline_thickness(factor);
}

void
View::adjust_boldness(double factor)
{
	st.adjust_boldness(factor);
}

void
View::scale(double factor)
{
	scale_ *= factor;
}

void
View::translate(double dx, double dy)
{
	translate_.x += dx / scale_;
	translate_.y += dy / scale_;
}

void
View::apply_transform(float *mat)
{
	int viewport[4];
	glGetIntegerv (GL_VIEWPORT, viewport);
	GLint width  = viewport[2];
	GLint height = viewport[3];

	// View transform
	m4Scale (mat, scale_, scale_, 1);
	m4Translate (mat, translate_.x, translate_.y, 0);

	// Perspective
	{
		double d = std::max (width, height);
		double near = d / perspective;
		double far = near + d;
		double factor = near / (2 * near + d);
		m4Frustum (mat, -width * factor, width * factor, -height * factor, height * factor, near, far);
		m4Translate (mat, 0, 0, -(near + d * .5));
	}

	// Rotate
	//float m[4][4];
	//build_rotmatrix (m, quat);
	//m4MultMatrix(mat, &m[0][0]);

	// Fix 'up'
	m4Scale (mat, 1, -1, 1);
}


/* return current time in milli-seconds */
static long
current_time (void)
{
	return glfwGetTime();
}

void
View::toggle_fullscreen()
{
#if 0
	fullscreen = !fullscreen;
	if (fullscreen) {
		x = glutGet(GLUT_WINDOW_X);
		y = glutGet(GLUT_WINDOW_Y);
		width  = glutGet(GLUT_WINDOW_WIDTH);
		height = glutGet(GLUT_WINDOW_HEIGHT);
		glutFullScreen();
	} else {
		glutReshapeWindow(width, height);
		glutPositionWindow(x, y);
	}
#endif
}

void
View::toggle_debug()
{
	st.toggle_debug();
}


void
View::reshape_func(int width, int height)
{
	glViewport (0, 0, width, height);
	// glutPostRedisplay ();
}

#define STEP 1.05
void
View::keyboard_func(GLFWwindow *window, int key, int scancode, int action, int mods)
{
	switch (key)
	{
		case '\033':
		case GLFW_KEY_Q:
			glfwSetWindowShouldClose(window, 1);
			break;

		case 'f':
			toggle_fullscreen();
			break;

		case 'd':
			toggle_debug();
			break;

		case 'o':
			toggle_outline();
			break;
		case 'p':
			scale_outline_thickness(STEP);
			break;
		case 'i':
			scale_outline_thickness(1. / STEP);
			break;

		case '0':
			adjust_boldness(+.01);
			break;
		case '9':
			adjust_boldness(-.01);
			break;


		case 'a':
			scale_contrast(STEP);
			break;
		case 'z':
			scale_contrast(1. / STEP);
			break;
		case 'g':
			scale_gamma_adjust(STEP);
			break;
		case 'b':
			scale_gamma_adjust(1. / STEP);
			break;

		case GLFW_KEY_EQUAL:
			scale(STEP);
			break;
		case '-':
			scale(1. / STEP);
			break;

		case GLFW_KEY_K:
			translate(0, -.1);
			break;
		case GLFW_KEY_J:
			translate(0, +.1);
			break;
		case GLFW_KEY_H:
			translate(+.1, 0);
			break;
		case GLFW_KEY_L:
			translate(-.1, 0);
			break;

		case 'r':
			reset();
			break;

		default:
			return;
	}
}

void
View::special_func(int key, int x, int y)
{
#if 0
	switch (key)
	{
		case GLUT_KEY_UP:
			translate(0, -.1);
			break;
		case GLUT_KEY_DOWN:
			translate(0, +.1);
			break;
		case GLUT_KEY_LEFT:
			translate(+.1, 0);
			break;
		case GLUT_KEY_RIGHT:
			translate(-.1, 0);
			break;

		default:
			return;
	}
#endif
	// glutPostRedisplay ();
}

void
View::mouse_func(int button, int state, int x, int y)
{
#if 0
	if (state == GLUT_DOWN) {
		buttons |= (1 << button);
		click_handled = false;
	} else
		buttons &= !(1 << button);
	// modifiers = glutGetModifiers ();

	switch (button) {
	case GLUT_RIGHT_BUTTON:
		switch (state) {
		case GLUT_DOWN:
			if (animate) {
				toggle_animation();
				click_handled = true;
			}
			break;
		case GLUT_UP:
			if (!animate)
			{
				if (!dragged && !click_handled)
					toggle_animation();
				else if (dt) {
					double speed = hypot (dx, dy) / dt;
					if (speed > 0.1)
						toggle_animation();
				}
				dx = dy = dt = 0;
			}
			break;
		}
		break;

#if !defined(GLUT_WHEEL_UP)
#define GLUT_WHEEL_UP 3
#define GLUT_WHEEL_DOWN 4
#endif
	case GLUT_WHEEL_UP:
		scale(STEP);
		break;

	case GLUT_WHEEL_DOWN:
		scale(1. / STEP);
		break;
	}
#endif

	beginx = lastx = x;
	beginy = lasty = y;
	dragged = false;

	// glutPostRedisplay ();
}

void
View::motion_func(int x, int y)
{
	dragged = true;

	int viewport[4];
	glGetIntegerv (GL_VIEWPORT, viewport);
#if 0
	GLuint width  = viewport[2];
	GLuint height = viewport[3];

	if (buttons & (1 << GLUT_LEFT_BUTTON))
	{
		if (modifiers & GLUT_ACTIVE_SHIFT) {
			/* adjust contrast/gamma */
			scale_gamma_adjust(1 - ((y - lasty) / height));
			scale_contrast(1 + ((x - lastx) / width));
		} else {
			/* translate */
			translate(
					+2 * (x - lastx) / width,
					-2 * (y - lasty) / height);
		}
	}

	if (buttons & (1 << GLUT_RIGHT_BUTTON))
	{
		if (modifiers & GLUT_ACTIVE_SHIFT) {
			/* adjust perspective */
			scale_perspective(1 - ((y - lasty) / height) * 5);
		} else {
			/* rotate */
			float dquat[4];
			trackball (dquat,
					(2.0*lastx -     width) / width,
					(   height - 2.0*lasty) / height,
					(    2.0*x -     width) / width,
					(   height -     2.0*y) / height );

			dx = x - lastx;
			dy = y - lasty;
			dt = current_time () - lastt;

			add_quats (dquat, quat, quat);

			if (dt) {
				vcopy (dquat, rot_axis);
				vnormal (rot_axis);
				rot_speed = 2 * acos (dquat[3]) / dt;
			}
		}
	}

	if (buttons & (1 << GLUT_MIDDLE_BUTTON))
	{
		/* scale */
		double factor = 1 - ((y - lasty) / height) * 5;
		scale(factor);
		/* adjust translate so we scale centered at the drag-begin mouse position */
		translate(
				+(2. * beginx / width  - 1) * (1 - factor),
				-(2. * beginy / height - 1) * (1 - factor));
	}
#endif

	lastx = x;
	lasty = y;
	lastt = current_time ();

	// glutPostRedisplay ();
}

void
View::display(glyphy_extents_t const &extents)
{
	int viewport[4];
	glGetIntegerv (GL_VIEWPORT, viewport);
	GLint width  = viewport[2];
	GLint height = viewport[3];


	float mat[16];

	m4LoadIdentity (mat);

	apply_transform(mat);

	// Buffer best-fit
	double content_scale = .9 * std::min (width  / (extents.max_x - extents.min_x),
			height / (extents.max_y - extents.min_y));
	m4Scale (mat, content_scale, content_scale, 1);
	// Center buffer
	m4Translate (mat,
			-(extents.max_x + extents.min_x) / 2.,
			-(extents.max_y + extents.min_y) / 2., 0);

	st.set_matrix(mat);

	glClearColor (1, 1, 1, 1);
	glClear (GL_COLOR_BUFFER_BIT);
}

void
View::setup()
{
	st.setup();
}
