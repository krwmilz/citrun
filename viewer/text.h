#ifndef TEXT_H
#define TEXT_H

#include <GL/glew.h>
#include <GL/freeglut.h>

#include <ft2build.h>
#include FT_FREETYPE_H

#include "shader_utils.h"
#include "draw.h"

class text : public drawable {
public:
	text();
	void draw();
	void idle();
private:
	std::string font_file_name;
	FT_Library ft;
	FT_Face face;
	FT_GlyphSlot g;
	GLuint vbo;
	shader text_shader;

	void render_text(const char *, float x, float y, float sx, float sy);
};

#endif
