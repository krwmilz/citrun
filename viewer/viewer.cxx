#include <err.h>

#include <iostream>
#include <vector>

#include <GL/glew.h>
#include <GL/freeglut.h>

#include "af_unix.h"
#include "text.h"


class window {
public:
	window(int argc, char *argv[]);
	void start();
	void add(drawable &);

private:
	static std::vector<drawable*> drawables;
	static af_unix socket;
	static void display();
	static void idle();
};

// fuckin c++
std::vector<drawable*> window::drawables;
af_unix window::socket;

window::window(int argc, char *argv[])
{
	glutInit(&argc, argv);
	glutInitContextVersion(2, 0);
	glutInitDisplayMode(GLUT_RGB);
	glutInitWindowSize(1600, 1200);
	glutCreateWindow("Basic Text");

	GLenum glew_status = glewInit();

	if (GLEW_OK != glew_status)
		errx(1, "%s", glewGetErrorString(glew_status));

	if (!GLEW_VERSION_2_0)
		errx(1, "No support for OpenGL 2.0 found");

	glutDisplayFunc(window::display);
	glutIdleFunc(idle);

	// This creates the socket with SOCK_NONBLOCK
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
	glClearColor(0, 0, 0, 1);
	glClear(GL_COLOR_BUFFER_BIT);

	/* Enable blending, necessary for our alpha texture */
	glEnable(GL_BLEND);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

	for (auto &d : drawables)
		d->draw();

	std::cerr << "window__display" << std::endl;

	glutSwapBuffers();
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
