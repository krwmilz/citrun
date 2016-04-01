#include <err.h>

#include <iostream>
#include <vector>

#include "af_unix.h"
#include "runtime_process.h"
#include "view.h"

#include "demo-buffer.h"
#include "demo-font.h"


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
	static std::vector<drawable*> drawables;
private:
	static void display();
	static void reshape_func(int, int);
	static void keyboard_func(unsigned char, int, int);
	static void special_func(int, int, int);
	static void mouse_func(int, int, int, int);
	static void motion_func(int, int);

	demo_glstate_t *st;
};

std::vector<drawable*> window::drawables;
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
	static_vu->print_help();

	FT_Init_FreeType(&ft_library);

#if defined(__OpenBSD__)
	const char *font_path = "/usr/X11R6/lib/X11/fonts/TTF/DejaVuSansMono.ttf";
#elif defined(__APPLE__)
	const char *font_path = "/Library/Fonts/Andale Mono.ttf";
#else
	errx(1, "PICK A FONT FOR THIS PLATFORM");
#endif
	ft_face = NULL;
	FT_New_Face(ft_library, font_path, /* face_index */ 0, &ft_face);

	font = demo_font_create(ft_face, demo_glstate_get_atlas(st));

	static_vu->setup();

	// This creates the socket with SOCK_NONBLOCK
	socket.set_listen();

	static_vu->toggle_animation();
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
	af_unix *temp_socket = window::socket.accept();
	if (temp_socket)
		window::drawables.push_back(new RuntimeProcess(temp_socket, buffer, font));

	for (auto &i : window::drawables)
		i->idle();

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
