#include <cmath>
#include <err.h>
#include <iostream>
#include <sstream>
#include <vector>

#include "af_unix.h"
#include "demo-font.h"
#include "gl_buffer.h"
#include "gl_view.h"
#include "runtime_proc.h"

#if defined(__OpenBSD__)
#define FONT_PATH "/usr/X11R6/lib/X11/fonts/TTF/DejaVuSansMono.ttf"
#elif defined(__APPLE__)
#define FONT_PATH "/Library/Fonts/Andale Mono.ttf"
#elif defined(__gnu_linux__)
#define FONT_PATH "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf"
#endif

class window {
public:
	window(int argc, char *argv[]);
	void start();

	static void idle_step();
	static void print_fps(int);
	static void next_frame(View *);

	static FT_Library ft_library;
	static FT_Face ft_face;

	static demo_font_t *font;
	static demo_buffer_t *buffer;

	static View *static_vu;
	static af_unix socket;
	static std::vector<RuntimeProcess*> drawables;
private:
	static void display();
	static void reshape_func(int, int);
	static void keyboard_func(unsigned char, int, int);
	static void special_func(int, int, int);
	static void mouse_func(int, int, int, int);
	static void motion_func(int, int);

	demo_glstate_t *st;
};

std::vector<RuntimeProcess*> window::drawables;
af_unix window::socket;
View *window::static_vu;

FT_Library window::ft_library;
FT_Face window::ft_face;

demo_font_t *window::font;
demo_buffer_t *window::buffer;

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

	static_vu = new View(st, buffer);

	FT_Init_FreeType(&ft_library);

	ft_face = NULL;
	FT_New_Face(ft_library, FONT_PATH, /* face_index */ 0, &ft_face);

	font = demo_font_create(ft_face, demo_glstate_get_atlas(st));

	static_vu->setup();

	socket.set_nonblock();
	socket.set_listen();

	static_vu->toggle_animation();

	glyphy_point_t top_left = { 0, 0 };
	demo_buffer_move_to(buffer, &top_left);
	demo_buffer_add_text(buffer, "waiting...", font, 1);
}

void
window::reshape_func(int width, int height)
{
	static_vu->reshape_func(width, height);
}

void
window::keyboard_func(unsigned char key, int x, int y)
{
	static_vu->keyboard_func(key, x, y);
}

void
window::special_func(int key, int x, int y)
{
	static_vu->special_func(key, x, y);
}

void
window::mouse_func(int button, int state, int x, int y)
{
	static_vu->mouse_func(button, state, x, y);
}

void
window::motion_func(int x, int y)
{
	static_vu->motion_func(x, y);
}

void
window::start()
{
	glutMainLoop();
}

void
window::display(void)
{
	static_vu->display();
}


/* Return current time in milli-seconds */
static long
current_time(void)
{
	return glutGet(GLUT_ELAPSED_TIME);
}

void
window::next_frame(View *vu)
{
	// First update everything that's already known.
	for (auto &rp : window::drawables) {

		rp->read_executions();

		glyphy_point_t tmp;
		for (auto &t : rp->m_tus) {
			size_t bytes_total = t.num_lines * sizeof(uint64_t);

			for (int i = 0; i < t.num_lines; i++) {
				if (t.exec_diffs[i] == 0)
					continue;

				// demo_buffer_add_text(buffer, ">>", font, 1);
			}
		}
		std::cout << "tick" << std::endl;
	}

	// Now check if there's any new connections pending.
	af_unix *temp_socket = window::socket.accept();
	if (temp_socket) {
		temp_socket->set_block();
		demo_buffer_clear(buffer);
		RuntimeProcess *conn = new RuntimeProcess(*temp_socket);
		window::drawables.push_back(conn);

		std::stringstream ss;
		ss << "program name:\t" << conn->m_progname << std::endl;
		ss << "code lines:\t" << conn->m_lines_total << std::endl;
		ss << "trnsltn units:\t" << conn->m_num_tus << std::endl;
		ss << "process id:\t" << conn->m_pid << std::endl;
		ss << "parent pid:\t" << conn->m_ppid << std::endl;
		ss << "process group:\t" << conn->m_pgrp << std::endl;

		glyphy_point_t cur_pos = { 0, 0 };
		demo_buffer_move_to(buffer, &cur_pos);

		demo_buffer_add_text(buffer, ss.str().c_str(), font, 2);

		demo_buffer_current_point(buffer, &cur_pos);
		double y_margin = cur_pos.y;

		/*
		 * T: total lines, known
		 * W: number of 80 char columns
		 * H: number of rows
		 *
		 * (1 ) W * 80 * H = T
		 * (2 ) W * 80 = H
		 * (2a) W = H / 80
		 * (1a) (H / 80) * 80 * H = T
		 * (1b) H^2 = T
		 * (1c) H = sqrt(T)
		 */
		// int rows_per_col = std::sqrt(lines_total) * 4;

		cur_pos.x = 0;
		glyphy_point_t tmp;
		for (auto &t : conn->m_tus) {
			demo_buffer_add_text(buffer, t.comp_file_path.c_str(), font, 1);
		}
	}

	glutPostRedisplay ();
}

void
window::idle_step(void)
{
	View *vu = static_vu;
	if (vu->animate) {
		next_frame (vu);
	}
	else
		glutIdleFunc(NULL);
}

void
window::print_fps(int ms)
{
	View *vu = static_vu;
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
	View *vu = window::static_vu;
	vu->num_frames = 0;
	vu->last_frame_time = vu->fps_start_time = current_time();
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
