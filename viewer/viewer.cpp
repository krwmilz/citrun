#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#include <GL/glew.h>
#include <GL/freeglut.h>

#define GLM_FORCE_RADIANS
#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>
#include <glm/gtc/type_ptr.hpp>

#include <ft2build.h>
#include FT_FREETYPE_H

#include <iostream>
#include <vector>

#include "shader_utils.h"

struct point {
	GLfloat x;
	GLfloat y;
	GLfloat s;
	GLfloat t;
};

class drawable {
public:
	virtual void draw() = 0;
};

class idleable {
public:
	virtual void idle() = 0;
};

class shader {
public:
	shader();
	void use();
	~shader();

	GLint attribute_coord;
	GLint uniform_tex;
	GLint uniform_color;
private:
	GLuint program;
};

shader::shader()
{
	program = create_program("text.v.glsl", "text.f.glsl");
	if(program == 0)
		exit(1);

	attribute_coord = get_attrib(program, "coord");
	uniform_tex = get_uniform(program, "tex");
	uniform_color = get_uniform(program, "color");

	if(attribute_coord == -1 || uniform_tex == -1 || uniform_color == -1)
		exit(1);
}

void
shader::use()
{
	glUseProgram(program);
}

shader::~shader()
{
	glDeleteProgram(program);
}


class text : public drawable {
public:
	text();
	void draw();
private:
	std::string font_file_name;
	FT_Library ft;
	FT_Face face;
	FT_GlyphSlot g;
	GLuint vbo;
	shader text_shader;

	void render_text(const char *, float x, float y, float sx, float sy);
};

text::text()
{
	font_file_name = "DejaVuSansMono.ttf";

	/* Initialize the FreeType2 library */
	if (FT_Init_FreeType(&ft)) {
		std::cerr << "Could not init freetype library" << std::endl;
		exit(1);
	}

	/* Load a font */
	if (FT_New_Face(ft, font_file_name.c_str(), 0, &face)) {
		std::cerr << "Could not open font " << font_file_name << std::endl;
		exit(1);
	}

	g = face->glyph;
	glGenBuffers(1, &vbo);
}

/**
 * Render text using the currently loaded font and currently set font size.
 * Rendering starts at coordinates (x, y), z is always 0.
 * The pixel coordinates that the FreeType2 library uses are scaled by (sx, sy).
 */
void
text::render_text(const char *text, float x, float y, float sx, float sy)
{
	const char *p;

	/* Create a texture that will be used to hold one "glyph" */
	GLuint tex;

	glActiveTexture(GL_TEXTURE0);
	glGenTextures(1, &tex);
	glBindTexture(GL_TEXTURE_2D, tex);
	glUniform1i(text_shader.uniform_tex, 0);

	/* We require 1 byte alignment when uploading texture data */
	glPixelStorei(GL_UNPACK_ALIGNMENT, 1);

	/* Clamping to edges is important to prevent artifacts when scaling */
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

	/* Linear filtering usually looks best for text */
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

	/* Set up the VBO for our vertex data */
	glEnableVertexAttribArray(text_shader.attribute_coord);
	glBindBuffer(GL_ARRAY_BUFFER, vbo);
	glVertexAttribPointer(text_shader.attribute_coord, 4, GL_FLOAT, GL_FALSE, 0, 0);

	/* Loop through all characters */
	for (p = text; *p; p++) {
		/* Try to load and render the character */
		if (FT_Load_Char(face, *p, FT_LOAD_RENDER))
			continue;

		/* Upload the "bitmap", which contains an 8-bit grayscale image, as an alpha texture */
		glTexImage2D(GL_TEXTURE_2D, 0, GL_ALPHA, g->bitmap.width, g->bitmap.rows, 0, GL_ALPHA, GL_UNSIGNED_BYTE, g->bitmap.buffer);

		/* Calculate the vertex and texture coordinates */
		float x2 = x + g->bitmap_left * sx;
		float y2 = -y - g->bitmap_top * sy;
		float w = g->bitmap.width * sx;
		float h = g->bitmap.rows * sy;

		point box[4] = {
			{x2, -y2, 0, 0},
			{x2 + w, -y2, 1, 0},
			{x2, -y2 - h, 0, 1},
			{x2 + w, -y2 - h, 1, 1},
		};

		/* Draw the character on the screen */
		glBufferData(GL_ARRAY_BUFFER, sizeof box, box, GL_DYNAMIC_DRAW);
		glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

		/* Advance the cursor to the start of the next character */
		x += (g->advance.x >> 6) * sx;
		y += (g->advance.y >> 6) * sy;
	}

	glDisableVertexAttribArray(text_shader.attribute_coord);
	glDeleteTextures(1, &tex);
}

void
text::draw()
{
	float sx = 2.0 / glutGet(GLUT_WINDOW_WIDTH);
	float sy = 2.0 / glutGet(GLUT_WINDOW_HEIGHT);

	// glUseProgram(program);
	text_shader.use();

	GLfloat black[4] = { 0, 0, 0, 1 };
	GLfloat red[4] = { 1, 0, 0, 1 };
	GLfloat transparent_green[4] = { 0, 1, 0, 0.5 };

	/* Set font size to 48 pixels, color to black */
	FT_Set_Pixel_Sizes(face, 0, 48);
	glUniform4fv(text_shader.uniform_color, 1, black);

	/* Effects of alignment */
	render_text("The Quick Brown Fox Jumps Over The Lazy Dog", -1 + 8 * sx, 1 - 50 * sy, sx, sy);
	render_text("The Misaligned Fox Jumps Over The Lazy Dog", -1 + 8.5 * sx, 1 - 100.5 * sy, sx, sy);

	/* Scaling the texture versus changing the font size */
	render_text("The Small Texture Scaled Fox Jumps Over The Lazy Dog", -1 + 8 * sx, 1 - 175 * sy, sx * 0.5, sy * 0.5);
	FT_Set_Pixel_Sizes(face, 0, 24);
	render_text("The Small Font Sized Fox Jumps Over The Lazy Dog", -1 + 8 * sx, 1 - 200 * sy, sx, sy);
	FT_Set_Pixel_Sizes(face, 0, 48);
	render_text("The Tiny Texture Scaled Fox Jumps Over The Lazy Dog", -1 + 8 * sx, 1 - 235 * sy, sx * 0.25, sy * 0.25);
	FT_Set_Pixel_Sizes(face, 0, 12);
	render_text("The Tiny Font Sized Fox Jumps Over The Lazy Dog", -1 + 8 * sx, 1 - 250 * sy, sx, sy);
	FT_Set_Pixel_Sizes(face, 0, 48);

	/* Colors and transparency */
	render_text("The Solid Black Fox Jumps Over The Lazy Dog", -1 + 8 * sx, 1 - 430 * sy, sx, sy);

	glUniform4fv(text_shader.uniform_color, 1, red);
	render_text("The Solid Red Fox Jumps Over The Lazy Dog", -1 + 8 * sx, 1 - 330 * sy, sx, sy);
	render_text("The Solid Red Fox Jumps Over The Lazy Dog", -1 + 28 * sx, 1 - 450 * sy, sx, sy);

	glUniform4fv(text_shader.uniform_color, 1, transparent_green);
	render_text("The Transparent Green Fox Jumps Over The Lazy Dog", -1 + 8 * sx, 1 - 380 * sy, sx, sy);
	render_text("The Transparent Green Fox Jumps Over The Lazy Dog", -1 + 18 * sx, 1 - 440 * sy, sx, sy);
}

class window {
public:
	window(int argc, char *argv[]);
	void start();
	void add(drawable &);

private:
	static std::vector<drawable*> drawables;
	static std::vector<idleable*> idleables;
	static void display();
	static void idle();
};

// fuckin c++
std::vector<drawable*> window::drawables;
std::vector<idleable*> window::idleables;

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

	for(auto  &d : drawables)
		d->draw();

	glutSwapBuffers();
}

void
window::idle(void)
{
	// printf("idling!\n");
}

int main(int argc, char *argv[]) {

	window gl_window(argc, argv);
	text gl_text;

	gl_window.add(gl_text);
	gl_window.start();

	return 0;
}
