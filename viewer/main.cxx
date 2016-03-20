#include <err.h>

#include <iostream>
#include <vector>

#include "default-text.h"
#include "af_unix.h"
#include "runtime_client.h"
#include "view.h"

#include "demo-buffer.h"
#include "demo-font.h"



class window {
public:
	window(int argc, char *argv[]);
	void start();

	static void idle_step();
	static void print_fps(int);
	static void timed_step(int);
	static void next_frame(demo_view_t *);

	static demo_view_t *static_vu;
	static af_unix socket;
	static std::vector<drawable*> drawables;
private:
	static void display();
	static void reshape_func(int, int);
	static void keyboard_func(unsigned char, int, int);
	static void special_func(int, int, int);
	static void mouse_func(int, int, int, int);
	static void motion_func(int, int);

	demo_glstate_t *st;
	demo_buffer_t *buffer;
	demo_font_t *font;
};

std::vector<drawable*> window::drawables;
af_unix window::socket;
demo_view_t *window::static_vu;

window::window(int argc, char *argv[])
{
	glutInit(&argc, argv);
	glutInitWindowSize(1600, 1200);
	glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGB);
	int window = glutCreateWindow("Source Code Visualizer");
	glutReshapeFunc(reshape_func);
	glutDisplayFunc(display);
	glutKeyboardFunc(keyboard_func);
	glutSpecialFunc(special_func);
	glutMouseFunc(mouse_func);
	glutMotionFunc(motion_func);

	GLenum glew_status = glewInit();
	if (GLEW_OK != glew_status)
		errx(1, "%s", glewGetErrorString(glew_status));
	if (!glewIsSupported("GL_VERSION_2_0"))
		errx(1, "No support for OpenGL 2.0 found");

	st = demo_glstate_create();
	buffer = demo_buffer_create();
	//vu = demo_view_create(st);
	static_vu = new demo_view_t(st, buffer);
	static_vu->demo_view_print_help();

	FT_Library ft_library;
	FT_Init_FreeType(&ft_library);

	FT_Face ft_face = NULL;
	FT_New_Face(ft_library, "DejaVuSansMono.ttf", /* face_index */ 0, &ft_face);

	font = demo_font_create(ft_face, demo_glstate_get_atlas(st));

	glyphy_point_t top_left = { 0, 0 };
	demo_buffer_move_to(buffer, &top_left);
	demo_buffer_add_text(buffer, default_text, font, 1);

	demo_font_print_stats(font);

	static_vu->demo_view_setup();

	// This creates the socket with SOCK_NONBLOCK
	socket.set_listen();
}

void
window::reshape_func(int width, int height)
{
	static_vu->demo_view_reshape_func(width, height);
}

void
window::keyboard_func(unsigned char key, int x, int y)
{
	static_vu->demo_view_keyboard_func(key, x, y);
}

void
window::special_func(int key, int x, int y)
{
	static_vu->demo_view_special_func(key, x, y);
}

void
window::mouse_func(int button, int state, int x, int y)
{
	static_vu->demo_view_mouse_func(button, state, x, y);
}

void
window::motion_func(int x, int y)
{
	static_vu->demo_view_motion_func(x, y);
}

void
window::start()
{
	glutMainLoop();
}

void
window::display(void)
{
	static_vu->demo_view_display();
}


/* return current time in milli-seconds */
static long
current_time (void)
{
	return glutGet (GLUT_ELAPSED_TIME);
}

void
window::next_frame(demo_view_t *vu)
{
	/*
	af_unix *temp_socket = window::socket.accept();
	if (temp_socket)
		window::drawables.push_back(new RuntimeClient(temp_socket, buffer, font));

	for (auto &i : window::drawables)
		i->idle();
	*/

	glutPostRedisplay ();
}

void
window::timed_step(int ms)
{
	demo_view_t *vu = static_vu;
	if (vu->animate) {
		glutTimerFunc (ms, timed_step, ms);
		next_frame (vu);
	}
}

void
window::idle_step(void)
{
	demo_view_t *vu = static_vu;
	if (vu->animate) {
		next_frame (vu);
	}
	else
		glutIdleFunc(NULL);
}

void
window::print_fps(int ms)
{
	demo_view_t *vu = static_vu;
	if (vu->animate) {
		glutTimerFunc (ms, print_fps, ms);
		long t = current_time ();
		LOGI ("%gfps\n", vu->num_frames * 1000. / (t - vu->fps_start_time));
		vu->num_frames = 0;
		vu->fps_start_time = t;
	} else
		vu->has_fps_timer = false;
}

void
start_animation()
{
	demo_view_t *vu = window::static_vu;
	vu->num_frames = 0;
	vu->last_frame_time = vu->fps_start_time = current_time();
	//glutTimerFunc (1000/60, timed_step, 1000/60);
	glutIdleFunc(window::idle_step);
	if (!vu->has_fps_timer) {
		vu->has_fps_timer = true;
		glutTimerFunc (5000, window::print_fps, 5000);
	}
}

int
main(int argc, char *argv[])
{
	window glut_window(argc, argv);
	glut_window.start();

	return 0;
}
