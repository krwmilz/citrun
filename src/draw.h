#ifndef DRAW_H
#define DRAW_H

#include <GL/glew.h>

struct point {
	GLfloat x;
	GLfloat y;
	GLfloat s;
	GLfloat t;
};

class drawable {
public:
	virtual void draw() = 0;
	virtual void idle() = 0;
};

#endif
