#include <err.h>

#include <iostream>
#include <vector>

#include "af_unix.h"
#include "text.h"

#include "default-text.h"
#include "demo-buffer.h"
#include "demo-font.h"
#include "demo-view.h"

demo_glstate_t *st;
demo_view_t *vu;
demo_buffer_t *buffer;

class window {
public:
	window(int argc, char *argv[]);
	void start();
	void add(drawable &);

private:
	static std::vector<drawable*> drawables;
	static af_unix socket;
	static void display();
	static void reshape_func(int, int);
	static void keyboard_func(unsigned char, int, int);
	static void special_func(int, int, int);
	static void mouse_func(int, int, int, int);
	static void motion_func(int, int);
	static void idle();

};

// fuckin c++
std::vector<drawable*> window::drawables;
af_unix window::socket;

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
	vu = demo_view_create(st);
	demo_view_print_help(vu);

	FT_Library ft_library;
	FT_Init_FreeType(&ft_library);

	FT_Face ft_face = NULL;
	FT_New_Face(ft_library, "DejaVuSansMono.ttf", /* face_index */ 0, &ft_face);

	demo_font_t *font = demo_font_create(ft_face, demo_glstate_get_atlas(st));

	buffer = demo_buffer_create();
	glyphy_point_t top_left = { 0, 0 };
	demo_buffer_move_to(buffer, &top_left);
	demo_buffer_add_text(buffer, default_text, font, 1);

	demo_font_print_stats(font);

	demo_view_setup(vu);

	// This creates the socket with SOCK_NONBLOCK
	socket.set_listen();
}

void
window::reshape_func(int width, int height)
{
	demo_view_reshape_func(vu, width, height);
}

void
window::keyboard_func(unsigned char key, int x, int y)
{
	demo_view_keyboard_func(vu, key, x, y);
}

void
window::special_func(int key, int x, int y)
{
	demo_view_special_func(vu, key, x, y);
}

void
window::mouse_func(int button, int state, int x, int y)
{
	demo_view_mouse_func(vu, button, state, x, y);
}

void
window::motion_func(int x, int y)
{
	demo_view_motion_func(vu, x, y);
}

void
window::start()
{
	glutMainLoop();
}

void
window::display(void)
{
	demo_view_display(vu, buffer);
}

void
window::idle(void)
{
	af_unix *temp_socket = socket.accept();
	if (temp_socket)
		drawables.push_back(new text(temp_socket));

	for (auto &i : drawables)
		i->idle();
}

int
main(int argc, char *argv[])
{
	window glut_window(argc, argv);
	glut_window.start();

	return 0;
}
