#include <iostream>
#include <vector>

#include <GL/glew.h>
#include <GL/freeglut.h>

#define GLM_FORCE_RADIANS
#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>
#include <glm/gtc/type_ptr.hpp>

#include "af_unix.h"
#include "text.h"


class window {
public:
	window(int argc, char *argv[]);
	void start();
	void add(drawable &);

private:
	static std::vector<drawable*> drawables;
	static af_unix_nonblock socket;
	static void display();
	static void idle();
};

// fuckin c++
std::vector<drawable*> window::drawables;
af_unix_nonblock window::socket;

window::window(int argc, char *argv[])
{
	glutInit(&argc, argv);
	glutInitContextVersion(2,0);
	glutInitDisplayMode(GLUT_RGB);
	glutInitWindowSize(1600, 1200);
	glutCreateWindow("Basic Text");

	GLenum glew_status = glewInit();

	if (GLEW_OK != glew_status) {
		std::cerr << "Error: " << glewGetErrorString(glew_status) << std::endl;
		exit(1);
	}

	if (!GLEW_VERSION_2_0) {
		std::cerr << "No support for OpenGL 2.0 found" << std::endl;
		exit(1);
	}

	glutDisplayFunc(display);
	glutIdleFunc(idle);

	// set socket to listening mode
	socket.set_listen();
}

void
window::start()
{
	glutMainLoop();
}

void
window::add(drawable &d)
{
	drawables.push_back(&d);
}

void
window::display(void)
{
	/* White background */
	glClearColor(1, 1, 1, 1);
	glClear(GL_COLOR_BUFFER_BIT);

	/* Enable blending, necessary for our alpha texture */
	glEnable(GL_BLEND);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

	for (auto &d : drawables)
		d->draw();

	glutSwapBuffers();
}

void
window::idle(void)
{
	af_unix_nonblock *temp_socket;

	temp_socket = socket.accept();
	if (temp_socket)
		drawables.push_back(new text(temp_socket));
	// socket.read();

	for (auto &i : drawables)
		i->idle();
}

int
main(int argc, char *argv[])
{
	window gl_window(argc, argv);
	gl_window.start();

	return 0;
}