#include <err.h>

#include <cassert>
#include <iostream>
#include <fstream>
#include <sstream>
#include <vector>

#include "text.h"

text::text(af_unix *sock) :
	socket(sock)
{
	assert(socket->read_all(num_tus) == 8);

	for (int i = 0; i < num_tus; i++) {
		uint64_t file_name_sz;
		assert(socket->read_all(file_name_sz) == 8);

		file_name.resize(file_name_sz);
		assert(socket->read_all((uint8_t *)&file_name[0], file_name_sz) == file_name_sz);

		read_file();

		assert(socket->read_all(num_lines) == 8);
		execution_counts.resize(num_lines);
	}
}

void
text::read_file()
{
	std::string line;
	std::ifstream file_stream(file_name);

	if (file_stream.is_open() == 0)
		errx(1, "ifstream.open()");

	while (std::getline(file_stream, line))
		source_file_contents.push_back(line);

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
}
