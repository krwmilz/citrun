#include <err.h>

#include <cassert>
#include <iostream>
#include <vector>

#include "text.h"

text::text(af_unix_nonblock *sock) :
	socket(sock),
	state(WRITE),
	font(FTGLPixmapFont("DejaVuSansMono.ttf")),
	buffer(NULL)
{
	if (font.Error())
		errx(1, "%s", "font error");

	uint8_t msg_type = 0;
	assert(socket->write_all(&msg_type, 1) == 1);

	assert(socket->read_block(num_tus) == 8);
	std::cerr << "text::text() num tus = " << num_tus << std::endl;

	for (int i = 0; i < num_tus; i++) {
		uint64_t file_name_sz;
		assert(socket->read_block(file_name_sz) == 8);
		std::cerr << "text::text() file name size= " << file_name_sz << std::endl;

		file_name = (char *)malloc(file_name_sz + 1);
		assert(socket->read_block((uint8_t *)file_name, file_name_sz) == file_name_sz);
		file_name[file_name_sz] = '\0';
		std::cerr << "text::text() file name = " << file_name << std::endl;

		assert(socket->read_block(num_lines) == 8);
		std::cerr << "text::text() num lines = " << num_lines << std::endl;
	}

	font.FaceSize(36);
	font.Render("Hello World!", 12, FTPoint(0, 36, 0));
	font.Render(file_name);
}

void
text::draw()
{
}

void
text::idle()
{
	if (state == READ) {
		size_t n = 0;
		n = socket->read_nonblock((uint8_t *)buffer + bytes_read, bytes_left);

		bytes_read += n;
		bytes_left -= n;

		if (bytes_left > 0)
			// There's more data coming
			return;

		std::cerr << "---" << std::endl;
		for (int i = 0; i < num_lines; i++) {
			std::cerr << "line " << i << ": " << buffer[i] << std::endl;
		}

		state = WRITE;
	}
	if (state == WRITE) {
		uint8_t msg_type = 1;
		if (socket->write_all(&msg_type, 1) != 1)
			// Couldn't write a request, try again later
			err(1, "write()");

		// Sent a successful request, listen for reply
		state = READ;

		if (buffer != NULL)
			free(buffer);

		buffer = (uint64_t *)malloc(num_lines * sizeof(uint64_t));
		if (buffer == NULL)
			err(1, "malloc");

		bytes_left = num_lines * sizeof(uint64_t);
		bytes_read = 0;
	}
}
