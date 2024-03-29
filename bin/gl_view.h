#ifndef VIEW_H
#define VIEW_H

#include "demo-common.h"
#include "gl_state.h"		// citrun::gl_state
#include <GLFW/glfw3.h>

class View {
public:
	View(citrun::gl_state &);
	~View();

	void reset();
	void reshape_func(int, int);
	void keyboard_func(GLFWwindow *, int, int, int, int);
	void special_func(int key, int x, int y);
	void mouse_func(int button, int state, int x, int y);
	void motion_func(int x, int y);
	void print_help();
	void display(glyphy_extents_t const &);
	void setup();

	/* Animation */
	bool animate;
	int num_frames;
	long fps_start_time;
	bool has_fps_timer;
	long last_frame_time;

private:
	void scale_gamma_adjust(double);
	void scale_contrast(double);
	void scale_perspective(double);
	void toggle_outline();
	void scale_outline_thickness(double);
	void adjust_boldness(double);
	void scale(double);
	void translate(double, double);
	void apply_transform(float *);
	void toggle_fullscreen();
	void toggle_debug();
	void advance_frame(long);

	unsigned int   refcount;

	citrun::gl_state &st;

	/* Output */
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
	double scale_;
	glyphy_point_t translate_;
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

#endif /* VIEW_H */
