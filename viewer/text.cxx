#include <err.h>

#include <cassert>
#include <iostream>
#include <fstream>
#include <sstream>
#include <vector>

#include "text.h"

text::text(af_unix *sock) :
	socket(sock),
	font(FTGLPixmapFont("DejaVuSansMono.ttf"))
{
	if (font.Error())
		errx(1, "%s", "font error");

	assert(socket->read_all(num_tus) == 8);
	std::cerr << "text::text() num tus = " << num_tus << std::endl;

	for (int i = 0; i < num_tus; i++) {
		uint64_t file_name_sz;
		assert(socket->read_all(file_name_sz) == 8);
		std::cerr << "text::text() file name size = " << file_name_sz << std::endl;

		file_name = (char *)malloc(file_name_sz + 1);
		assert(socket->read_all((uint8_t *)file_name, file_name_sz) == file_name_sz);
		file_name[file_name_sz] = '\0';
		std::cerr << "text::text() file name = " << file_name << std::endl;
		read_file();

		assert(socket->read_all(num_lines) == 8);
		execution_counts.resize(num_lines);
		std::cerr << "text::text() num lines = " << num_lines << std::endl;
	}

	font.FaceSize(24);

	font.Render(file_name);
	int vertical = num_lines * 24;
	for (auto &line : source_file_contents) {
		font.Render(&line[0], line.size(), FTPoint(0, vertical, 0));
		vertical -= 24;
	}
}

void
text::read_file()
{
	std::wstring line;
	std::wifstream file_stream(file_name);

	if (file_stream.is_open() == 0)
		errx(1, "ifstream.open()");

	while (std::getline(file_stream, line)) {
		source_file_contents.push_back(line);
		std::wcerr << line << std::endl;
	}

	file_stream.close();
}

void
text::draw()
{
}

void
text::idle()
{
	size_t bytes_total = num_lines * sizeof(uint64_t);
	assert(socket->read_all((uint8_t *)&execution_counts[0], bytes_total) == bytes_total);

	// Send response back
	uint8_t msg_type = 1;
	assert(socket->write_all(&msg_type, 1) == 1);

	int vertical = num_lines * 24;
	for (auto &count : execution_counts) {
		std::stringstream ss;
		ss << count;
		std::string s_count = ss.str();

		font.Render(&s_count[0], s_count.size(), FTPoint(600, vertical, 0));
		vertical -= 24;
	}
}
