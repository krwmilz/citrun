#include <cmath>
#include <GL/glew.h>
#include <err.h>
#include <iostream>
#include <vector>

#include "gl_buffer.h"
#include "gl_font.h"
#include "gl_view.h"
#include "process_dir.h"
#include "process_file.h"

#include <GLFW/glfw3.h>

View *static_vu;

void
keyboard_func(GLFWwindow *window, int key, int scancode, int action, int mods)
{
	static_vu->keyboard_func(window, key, scancode, action, mods);
}

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

	glfwSetKeyCallback(window, keyboard_func);

	// glutReshapeFunc(reshape_func);
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

	ProcessDir m_pdir;
	std::vector<ProcessFile> drawables;

	demo_glstate_t *st = demo_glstate_create();
	GlBuffer buffer;

	static_vu = new View(st);

	demo_font_t *font = demo_font_create(demo_glstate_get_atlas(st));

	static_vu->setup();

	glyphy_point_t top_left = { 0, 0 };
	buffer.move_to(&top_left);
	buffer.add_text("waiting...", font, 1);

	while (!glfwWindowShouldClose(window)) {

		for (std::string &file_name : m_pdir.scan())
			drawables.emplace_back(file_name, font);

		glyphy_extents_t extents;
		for (auto &i : drawables) {
			glyphy_extents_t t = i.get_extents();
			extents.max_x = std::max(extents.max_x, t.max_x);
			extents.max_y = std::max(extents.max_y, t.max_y);
			extents.min_x = std::min(extents.min_x, t.min_x);
			extents.min_y = std::min(extents.min_y, t.min_y);
		}

		// Set up view transforms
		static_vu->display(extents);

		buffer.draw();

		for (auto &i : drawables)
			i.display();

		glfwSwapBuffers(window);
		glfwPollEvents();
	}

	glfwDestroyWindow(window);
	glfwTerminate();

	return 0;
}
