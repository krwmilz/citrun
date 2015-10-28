#include <ft2build.h>
#include FT_FREETYPE_H
#include <GL/gl.h>
#include <GL/glext.h>
#include <GLES3/gl31.h>

#include <err.h>

class Text {
public:
	Text();
	int draw_source_file(const char **lines);

private:
	FT_Library ft;
	FT_Face face;
	FT_GlyphSlot g;

	void render_text(const char *, float x, float y, float sx, float sy);
};

int
main(void)
{
	GLuint tex;
	glActiveTexture(GL_TEXTURE0);
	glGenTextures(1, &tex);
	glBindTexture(GL_TEXTURE_2D, tex);
	glUniform1i(uniform_tex, 0);

	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

	glPixelStorei(GL_UNPACK_ALIGNMENT, 1);

	GLuint vbo;
	glGenBuffers(1, &vbo);
	glEnableVertexAttribArray(attribute_coord);
	glBindBuffer(GL_ARRAY_BUFFER, vbo);
	glVertexAttribPointer(attribute_coord, 4, GL_FLOAT, GL_FALSE, 0, 0);

	Text text;
	text.draw_source_file(NULL);
}

Text::Text()
{
	if (FT_Init_FreeType(&ft))
		err(1, "Could not init freetype library\n");

	if (FT_New_Face(ft, "DejaVuSans.ttf", 0, &face))
		err(1, "Could not open font\n");

	FT_Set_Pixel_Sizes(face, 0, 48);
	g = face->glyph;
}

void
Text::render_text(const char *text, float x, float y, float sx, float sy)
{
	const char *p;

	for (p = text; *p; p++) {
		if (FT_Load_Char(face, *p, FT_LOAD_RENDER))
			continue;

		glTexImage2D(GL_TEXTURE_2D,
				0,
				GL_RED,
				g->bitmap.width,
				g->bitmap.rows,
				0,
				GL_RED,
				GL_UNSIGNED_BYTE,
				g->bitmap.buffer
			    );

		float x2 = x + g->bitmap_left * sx;
		float y2 = -y - g->bitmap_top * sy;
		float w = g->bitmap.width * sx;
		float h = g->bitmap.rows * sy;

		GLfloat box[4][4] = {
			{x2,	-y2,		0, 0},
			{x2 + w,	-y2,	1, 0},
			{x2,	-y2 - h, 	0, 1},
			{x2 + w, -y2 - h,	1, 1},
		};

		glBufferData(GL_ARRAY_BUFFER, sizeof box, box, GL_DYNAMIC_DRAW);
		glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

		x += (g->advance.x >> 6) * sx;
		y += (g->advance.y >> 6) * sy;
	}
}
