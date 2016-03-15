#include <err.h>

#include <iostream>
#include <vector>

#include "text.h"

text::text(af_unix_nonblock *sock) :
	socket(sock),
	state(WRITE_REQUEST),
	font(FTGLPixmapFont("DejaVuSansMono.ttf"))
{
	if (font.Error())
		errx(1, "%s", "font error");

	font.FaceSize(72);
	font.Render("Hello World!");
	font.Render("Hello World!");
}

void
text::draw()
{
}

void
text::parse_buffer()
{
	uint64_t off = 0;
	/* Read 8 bytes from beginning */
	uint64_t num_tus = buffer[off];
	off += 8;

	std::cerr << __func__ << ": num tus = " << num_tus << std::endl;

	for (int i = 0; i < num_tus; i++) {
		//file_name_sz = buffer[off];
		off += 8;

		// file_name = 
	}
}

void
text::idle()
{
	std::cerr << "text::idle() enter" << std::endl;
	std::cerr << "text::idle() state = " << state << std::endl;

	if (state == WRITE_REQUEST) {
		uint8_t zero = 0;
		if (socket->write_all(&zero, 1) == 1)
			state = READ_HEADER;
		else
			errx(1, "%s", "write_all() failed");
	}
	if (state == READ_HEADER) {
		msg_size = 0;
		size_t n = socket->read_all((uint8_t *)&msg_size, 8);

		if (n == 0)
			return;
		else if (n == 8)
			state = READ_MSG;
		else
			errx(1, "%s %zu bytes", "read_all():", n);

		std::cerr << "text::idle() msg size is " << msg_size << std::endl;

		buffer = (uint8_t *)malloc(msg_size);
		if (buffer == NULL)
			err(1, "malloc");

		bytes_left = msg_size;
		bytes_read = 0;
	}
	if (state == READ_MSG) {
		size_t n = socket->read_all(buffer + bytes_read, bytes_left);

		std::cerr << "text::idle() READ_MSG read " << n << " bytes" << std::endl;

		bytes_read += n;
		bytes_left -= n;

		if (bytes_left <= 0) {
			//parse_buffer();
			free(buffer);
			state = WRITE_REQUEST;
			std::cerr << "text::idle() got full message" << std::endl;
			std::cerr << "text::idle()  ==> resetting" << std::endl;
		}
	}
}
