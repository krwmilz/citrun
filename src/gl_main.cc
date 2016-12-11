#include <cmath>
#include <err.h>
#include <iostream>
#include <sstream>
#include <vector>

#include "demo-font.h"
#include "gl_buffer.h"
#include "gl_view.h"
#include "process_dir.h"
#include "process_file.h"

#include <GLFW/glfw3.h>

#if defined(__OpenBSD__)
#define FONT_PATH "/usr/X11R6/lib/X11/fonts/TTF/DejaVuSansMono.ttf"
#elif defined(__APPLE__)
#define FONT_PATH "/Library/Fonts/Andale Mono.ttf"
#elif defined(__gnu_linux__)
#define FONT_PATH "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf"
#endif

demo_glstate_t *st;

std::vector<ProcessFile> drawables;
ProcessDir m_pdir;
View *static_vu;

FT_Library ft_library;
FT_Face ft_face;

demo_font_t *font;
demo_buffer_t *buffer;

void
reshape_func(int width, int height)
{
	static_vu->reshape_func(width, height);
}

void
keyboard_func(unsigned char key, int x, int y)
{
	static_vu->keyboard_func(key, x, y);
}

void
special_func(int key, int x, int y)
{
	static_vu->special_func(key, x, y);
}

void
mouse_func(int button, int state, int x, int y)
{
	static_vu->mouse_func(button, state, x, y);
}

void
motion_func(int x, int y)
{
	static_vu->motion_func(x, y);
}

void
display(void)
{
	static_vu->display();
}


/* Return current time in milli-seconds */
static long
current_time(void)
{
	//return glutGet(GLUT_ELAPSED_TIME);
	return glfwGetTime();
}

void
add_new_process(std::string const &file_name)
{
	drawables.push_back(ProcessFile(file_name));
	ProcessFile *pfile = &drawables.back();

	demo_buffer_clear(buffer);

	std::stringstream ss;
	ss << "program name:\t" << pfile->progname() << std::endl;
	ss << "trnsltn units:\t" << pfile->m_tus.size() << std::endl;
	ss << "process id:\t" << pfile->getpid() << std::endl;
	ss << "parent pid:\t" << pfile->getppid() << std::endl;
	ss << "process group:\t" << pfile->getpgrp() << std::endl;

	glyphy_point_t cur_pos = { 0, 0 };
	demo_buffer_move_to(buffer, &cur_pos);

	demo_buffer_add_text(buffer, ss.str().c_str(), font, 2);

	demo_buffer_current_point(buffer, &cur_pos);

	cur_pos.x = 0;
	for (auto &t : pfile->m_tus) {
		demo_buffer_add_text(buffer, t.comp_file_path().c_str(), font, 1);
	}
}

void
next_frame(View *vu)
{
	std::vector<std::string> *new_files = m_pdir.scan();
	for (std::string &file_name : *new_files)
		add_new_process(file_name);

	delete new_files;

	for (auto &rp : drawables) {
		// rp.read_executions();

		//glyphy_point_t tmp;
		for (auto &t : rp.m_tus) {
			//size_t bytes_total = t.num_lines * sizeof(uint64_t);

			for (unsigned int i = 0; i < t.num_lines(); i++) {
				//if (t.exec_counts[i] == 0)
				//	continue;

				// demo_buffer_add_text(buffer, ">>", font, 1);
			}
		}
		std::cout << "tick" << std::endl;
	}

	// glutPostRedisplay ();
}

void
print_fps(int ms)
{
	View *vu = static_vu;
	if (vu->animate) {
		// glutTimerFunc (ms, print_fps, ms);
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
	View *vu = static_vu;
	vu->num_frames = 0;
	vu->last_frame_time = vu->fps_start_time = current_time();
	// glutIdleFunc(idle_step);
	if (!vu->has_fps_timer) {
		vu->has_fps_timer = true;
		// glutTimerFunc (5000, print_fps, 5000);
	}
}

#if 0
int
main(int argc, char *argv[])
{
	glutInit(&argc, argv);
	glutInitWindowSize(1600, 1200);
	glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGB);
	glutCreateWindow("C It Run");
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

	static_vu->toggle_animation();

	glyphy_point_t top_left = { 0, 0 };
	demo_buffer_move_to(buffer, &top_left);
	demo_buffer_add_text(buffer, "waiting...", font, 1);

	glutMainLoop();

	return 0;
}
#endif

static void
error_callback(int error, const char *desc)
{
	fprintf(stderr, "Error: %s\n", desc);
}

int
main(int argc, char *argv[])
{
	GLFWwindow *window;

	glfwSetErrorCallback(error_callback);

	if (!glfwInit())
		return 1;

	glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 2);
	glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 0);

	window = glfwCreateWindow(1600, 1200, "C It Run", NULL, NULL);
	if (window == NULL) {
		glfwTerminate();
		return 1;
	}

	// glfwSetKeyCallback(window, key_callback);

	// glutReshapeFunc(reshape_func);
	// glutDisplayFunc(display);
	// glutKeyboardFunc(keyboard_func);
	// glutSpecialFunc(special_func);
	// glutMouseFunc(mouse_func);
	// glutMotionFunc(motion_func);

	glfwMakeContextCurrent(window);
	glfwSwapInterval(1);

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

	static_vu->toggle_animation();

	glyphy_point_t top_left = { 0, 0 };
	demo_buffer_move_to(buffer, &top_left);
	demo_buffer_add_text(buffer, "waiting...", font, 1);

	while (!glfwWindowShouldClose(window)) {

		next_frame(static_vu);
		static_vu->display();

		glfwSwapBuffers(window);
		glfwPollEvents();
	}

	glfwDestroyWindow(window);
	glfwTerminate();

	return 0;
}
