#ifndef DEMO_VIEW_H
#define DEMO_VIEW_H

#include "demo-common.h"
#include "demo-buffer.h"
#include "demo-glstate.h"

class demo_view_t {
public:
	demo_view_t(demo_glstate_t *, demo_buffer_t *);
	~demo_view_t();

	void demo_view_reset();
	void demo_view_reshape_func(int, int);
	void demo_view_keyboard_func(unsigned char key, int x, int y);
	void demo_view_special_func(int key, int x, int y);
	void demo_view_mouse_func(int button, int state, int x, int y);
	void demo_view_motion_func(int x, int y);
	void demo_view_print_help();
	void demo_view_display();
	void demo_view_setup();

	/* Animation */
	bool animate;
	int num_frames;
	long fps_start_time;
	bool has_fps_timer;
	long last_frame_time;
private:
	void demo_view_scale_gamma_adjust(double);
	void demo_view_scale_contrast(double);
	void demo_view_scale_perspective(double);
	void demo_view_toggle_outline();
	void demo_view_scale_outline_thickness(double);
	void demo_view_adjust_boldness(double);
	void demo_view_scale(double);
	void demo_view_translate(double, double);
	void demo_view_apply_transform(float *);
	void demo_view_toggle_animation();
	void demo_view_toggle_vsync();
	void demo_view_toggle_srgb();
	void demo_view_toggle_fullscreen();
	void demo_view_toggle_debug();
	void advance_frame(long);

	unsigned int   refcount;

	demo_glstate_t *st;
	demo_buffer_t *buffer;

	/* Output */
	GLint vsync;
	glyphy_bool_t srgb;
	glyphy_bool_t fullscreen;

	/* Mouse handling */
	int buttons;
	int modifiers;
	bool dragged;
	bool click_handled;
	double beginx, beginy;
	double lastx, lasty, lastt;
	double dx,dy, dt;

	/* Transformation */
	float quat[4];
	double scale;
	glyphy_point_t translate;
	double perspective;

	/* Animation */
	float rot_axis[3];
	float rot_speed;

	/* Window geometry just before going fullscreen */
	int x;
	int y;
	int width;
	int height;
};

#endif /* DEMO_VIEW_H */
