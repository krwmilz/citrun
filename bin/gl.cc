#include <GL/glew.h>
#include <GLFW/glfw3.h>
#include <err.h>

#include "gl_main.h"


void
keyboard_func(GLFWwindow *window, int key, int scancode, int action, int mods)
{
	//static_vu->keyboard_func(window, key, scancode, action, mods);
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
	glfwWindowHint(GLFW_SRGB_CAPABLE, 1);

	window = glfwCreateWindow(1600, 1200, "C It Run", NULL, NULL);
	if (window == NULL) {
		glfwTerminate();
		return 1;
	}

	glfwSetKeyCallback(window, keyboard_func);

	glfwMakeContextCurrent(window);
	glfwSwapInterval(1);

	GLenum glew_status = glewInit();
	if (GLEW_OK != glew_status)
		errx(1, "%s", glewGetErrorString(glew_status));
	if (!glewIsSupported("GL_VERSION_2_0"))
		errx(1, "No support for OpenGL 2.0 found");

	citrun::gl_main main;

	while (!glfwWindowShouldClose(window)) {

		main.tick();

		glfwSwapBuffers(window);
		glfwPollEvents();
	}

	glfwDestroyWindow(window);
	glfwTerminate();

	return 0;
}
