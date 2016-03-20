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

#include "demo-view.h"
#include "af_unix.h"

extern "C" {
#include "trackball.h"
#include "matrix4x4.h"
}

#include <sys/time.h>

void start_animation();

demo_view_t::demo_view_t(demo_glstate_t *st, demo_buffer_t *buf) :
	st(st),
	buffer(buf),
	fullscreen(false),
	animate(false),
	refcount(1)
{
	TRACE();

	demo_view_reset();
}

#if 0
demo_view_t *
demo_view_reference (demo_view_t *vu)
{
	if (vu) vu->refcount++;
	return vu;
}
#endif

demo_view_t::~demo_view_t()
{
	assert (refcount == 1);
}


#define ANIMATION_SPEED 1. /* Default speed, in radians second. */
void
demo_view_t::demo_view_reset()
{
	perspective = 4;
	scale = 1;
	translate.x = translate.y = 0;
	trackball (quat , 0.0, 0.0, 0.0, 0.0);
	vset (rot_axis, 0., 0., 1.);
	rot_speed = ANIMATION_SPEED / 1000.;
}

void
demo_view_t::demo_view_scale_gamma_adjust(double factor)
{
	demo_glstate_scale_gamma_adjust(st, factor);
}

void
demo_view_t::demo_view_scale_contrast(double factor)
{
	demo_glstate_scale_contrast (st, factor);
}

void
demo_view_t::demo_view_scale_perspective(double factor)
{
	perspective = clamp (perspective * factor, .01, 100.);
}

void
demo_view_t::demo_view_toggle_outline()
{
	demo_glstate_toggle_outline(st);
}

void
demo_view_t::demo_view_scale_outline_thickness(double factor)
{
	demo_glstate_scale_outline_thickness(st, factor);
}

void
demo_view_t::demo_view_adjust_boldness(double factor)
{
	demo_glstate_adjust_boldness(st, factor);
}

void
demo_view_t::demo_view_scale(double factor)
{
	scale *= factor;
}

void
demo_view_t::demo_view_translate(double dx, double dy)
{
	translate.x += dx / scale;
	translate.y += dy / scale;
}

void
demo_view_t::demo_view_apply_transform(float *mat)
{
	int viewport[4];
	glGetIntegerv (GL_VIEWPORT, viewport);
	GLint width  = viewport[2];
	GLint height = viewport[3];

	// View transform
	m4Scale (mat, scale, scale, 1);
	m4Translate (mat, translate.x, translate.y, 0);

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
	float m[4][4];
	build_rotmatrix (m, quat);
	m4MultMatrix(mat, &m[0][0]);

	// Fix 'up'
	m4Scale (mat, 1, -1, 1);
}


/* return current time in milli-seconds */
static long
current_time (void)
{
	return glutGet(GLUT_ELAPSED_TIME);
}

void
demo_view_t::demo_view_toggle_animation()
{
	animate = !animate;
	if (animate)
		start_animation();
}

void
demo_view_t::demo_view_toggle_vsync()
{
	vsync = !vsync;
	LOGI ("Setting vsync %s.\n", vsync ? "on" : "off");
#if defined(__APPLE__)
	CGLSetParameter(CGLGetCurrentContext(), kCGLCPSwapInterval, &vsync);
#elif defined(__WGLEW__)
	if (wglewIsSupported ("WGL_EXT_swap_control"))
		wglSwapIntervalEXT (vsync);
	else
		LOGW ("WGL_EXT_swal_control not supported; failed to set vsync\n");
#elif defined(__GLXEW_H__)
	if (glxewIsSupported ("GLX_SGI_swap_control"))
		glXSwapIntervalSGI (vsync);
	else
		LOGW ("GLX_SGI_swap_control not supported; failed to set vsync\n");
#else
	LOGW ("No vsync extension found; failed to set vsync\n");
#endif
}

void
demo_view_t::demo_view_toggle_srgb()
{
	srgb = !srgb;
	LOGI ("Setting sRGB framebuffer %s.\n", srgb ? "on" : "off");
#if defined(GL_FRAMEBUFFER_SRGB) && defined(GL_FRAMEBUFFER_SRGB_CAPABLE_EXT)
	GLboolean available = false;
	if ((glewIsSupported ("GL_ARB_framebuffer_sRGB") || glewIsSupported ("GL_EXT_framebuffer_sRGB")) &&
			(glGetBooleanv (GL_FRAMEBUFFER_SRGB_CAPABLE_EXT, &available), available)) {
		if (srgb)
			glEnable (GL_FRAMEBUFFER_SRGB);
		else
			glDisable (GL_FRAMEBUFFER_SRGB);
	} else
#endif
		LOGW ("No sRGB framebuffer extension found; failed to set sRGB framebuffer\n");
}

void
demo_view_t::demo_view_toggle_fullscreen()
{
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
}

void
demo_view_t::demo_view_toggle_debug()
{
	demo_glstate_toggle_debug(st);
}


void
demo_view_t::demo_view_reshape_func(int width, int height)
{
	glViewport (0, 0, width, height);
	glutPostRedisplay ();
}

#define STEP 1.05
void
demo_view_t::demo_view_keyboard_func(unsigned char key, int x, int y)
{
	switch (key)
	{
		case '\033':
		case 'q':
			exit (0);
			break;

		case ' ':
			demo_view_toggle_animation();
			break;
		case 'v':
			demo_view_toggle_vsync();
			break;

		case 'f':
			demo_view_toggle_fullscreen();
			break;

		case 'd':
			demo_view_toggle_debug();
			break;

		case 'o':
			demo_view_toggle_outline();
			break;
		case 'p':
			demo_view_scale_outline_thickness(STEP);
			break;
		case 'i':
			demo_view_scale_outline_thickness(1. / STEP);
			break;

		case '0':
			demo_view_adjust_boldness(+.01);
			break;
		case '9':
			demo_view_adjust_boldness(-.01);
			break;


		case 'a':
			demo_view_scale_contrast(STEP);
			break;
		case 'z':
			demo_view_scale_contrast(1. / STEP);
			break;
		case 'g':
			demo_view_scale_gamma_adjust(STEP);
			break;
		case 'b':
			demo_view_scale_gamma_adjust(1. / STEP);
			break;
		case 'c':
			demo_view_toggle_srgb();
			break;

		case '=':
			demo_view_scale(STEP);
			break;
		case '-':
			demo_view_scale(1. / STEP);
			break;

		case 'k':
			demo_view_translate(0, -.1);
			break;
		case 'j':
			demo_view_translate(0, +.1);
			break;
		case 'h':
			demo_view_translate(+.1, 0);
			break;
		case 'l':
			demo_view_translate(-.1, 0);
			break;

		case 'r':
			demo_view_reset();
			break;

		default:
			return;
	}
	glutPostRedisplay ();
}

void
demo_view_t::demo_view_special_func(int key, int x, int y)
{
	switch (key)
	{
		case GLUT_KEY_UP:
			demo_view_translate(0, -.1);
			break;
		case GLUT_KEY_DOWN:
			demo_view_translate(0, +.1);
			break;
		case GLUT_KEY_LEFT:
			demo_view_translate(+.1, 0);
			break;
		case GLUT_KEY_RIGHT:
			demo_view_translate(-.1, 0);
			break;

		default:
			return;
	}
	glutPostRedisplay ();
}

void
demo_view_t::demo_view_mouse_func(int button, int state, int x, int y)
{
	if (state == GLUT_DOWN) {
		buttons |= (1 << button);
		click_handled = false;
	} else
		buttons &= !(1 << button);
	modifiers = glutGetModifiers ();

	switch (button) {
	case GLUT_RIGHT_BUTTON:
		switch (state) {
		case GLUT_DOWN:
			if (animate) {
				demo_view_toggle_animation();
				click_handled = true;
			}
			break;
		case GLUT_UP:
			if (!animate)
			{
				if (!dragged && !click_handled)
					demo_view_toggle_animation();
				else if (dt) {
					double speed = hypot (dx, dy) / dt;
					if (speed > 0.1)
						demo_view_toggle_animation();
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
		demo_view_scale(STEP);
		break;

	case GLUT_WHEEL_DOWN:
		demo_view_scale(1. / STEP);
		break;
	}

	beginx = lastx = x;
	beginy = lasty = y;
	dragged = false;

	glutPostRedisplay ();
}

void
demo_view_t::demo_view_motion_func(int x, int y)
{
	dragged = true;

	int viewport[4];
	glGetIntegerv (GL_VIEWPORT, viewport);
	GLuint width  = viewport[2];
	GLuint height = viewport[3];

	if (buttons & (1 << GLUT_LEFT_BUTTON))
	{
		if (modifiers & GLUT_ACTIVE_SHIFT) {
			/* adjust contrast/gamma */
			demo_view_scale_gamma_adjust(1 - ((y - lasty) / height));
			demo_view_scale_contrast(1 + ((x - lastx) / width));
		} else {
			/* translate */
			demo_view_translate(
					+2 * (x - lastx) / width,
					-2 * (y - lasty) / height);
		}
	}

	if (buttons & (1 << GLUT_RIGHT_BUTTON))
	{
		if (modifiers & GLUT_ACTIVE_SHIFT) {
			/* adjust perspective */
			demo_view_scale_perspective(1 - ((y - lasty) / height) * 5);
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
		demo_view_scale(factor);
		/* adjust translate so we scale centered at the drag-begin mouse position */
		demo_view_translate(
				+(2. * beginx / width  - 1) * (1 - factor),
				-(2. * beginy / height - 1) * (1 - factor));
	}

	lastx = x;
	lasty = y;
	lastt = current_time ();

	glutPostRedisplay ();
}

void
demo_view_t::demo_view_print_help()
{
	LOGI ("Welcome to GLyphy demo\n");
}

void
demo_view_t::advance_frame(long dtime)
{
	if (animate) {
		float dquat[4];
		axis_to_quat (rot_axis, rot_speed * dtime, dquat);
		add_quats (dquat, quat, quat);
		num_frames++;
	}
}

void
demo_view_t::demo_view_display()
{
	long new_time = current_time ();
	advance_frame(new_time - last_frame_time);
	last_frame_time = new_time;

	int viewport[4];
	glGetIntegerv (GL_VIEWPORT, viewport);
	GLint width  = viewport[2];
	GLint height = viewport[3];


	float mat[16];

	m4LoadIdentity (mat);

	demo_view_apply_transform(mat);

	// Buffer best-fit
	glyphy_extents_t extents;
	demo_buffer_extents (buffer, NULL, &extents);
	double content_scale = .9 * std::min (width  / (extents.max_x - extents.min_x),
			height / (extents.max_y - extents.min_y));
	m4Scale (mat, content_scale, content_scale, 1);
	// Center buffer
	m4Translate (mat,
			-(extents.max_x + extents.min_x) / 2.,
			-(extents.max_y + extents.min_y) / 2., 0);

	demo_glstate_set_matrix(st, mat);

	glClearColor (1, 1, 1, 1);
	glClear (GL_COLOR_BUFFER_BIT);

	demo_buffer_draw (buffer);

	glutSwapBuffers ();
}

void
demo_view_t::demo_view_setup()
{
	if (!vsync)
		demo_view_toggle_vsync();
	if (!srgb)
		demo_view_toggle_srgb();
	demo_glstate_setup(st);
}
