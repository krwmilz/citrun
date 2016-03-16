#ifndef TEXT_H
#define TEXT_H

#include <GL/glew.h>
#include <GL/freeglut.h>

#include <FTGL/ftgl.h>

#include "af_unix.h"
#include "draw.h"

class text : public drawable {
public:
	text(af_unix_nonblock *);
	void draw();
	void idle();
private:
	af_unix_nonblock *socket;

	uint64_t num_tus;
	char *file_name;
	uint64_t num_lines;

	enum states {
		READ,
		WRITE
	};
	enum states state;
	uint64_t msg_size;
	uint64_t bytes_left;
	uint64_t bytes_read;
	uint64_t *buffer;

	void render_text(const char *, float x, float y, float sx, float sy);

	FTGLPixmapFont font;
};

#endif
