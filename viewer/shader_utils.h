#ifndef _CREATE_SHADER_H
#define _CREATE_SHADER_H
#include <GL/glew.h>

class shader {
public:
	shader();
	~shader();
	void use();

	GLint attribute_coord;
	GLint uniform_tex;
	GLint uniform_color;
private:
	GLuint program;
};

#endif
