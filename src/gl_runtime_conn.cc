#include <err.h>

#include <cassert>
#include <iostream>
#include <fstream>
#include <sstream>
#include <vector>

#include "gl_runtime_conn.h"

RuntimeProcess::RuntimeProcess(af_unix *sock, demo_buffer_t *buf, demo_font_t *f) :
	socket(sock),
	buffer(buf),
	font(f)
{
	uint64_t num_tus;
	socket->read_all(num_tus);
	translation_units.resize(num_tus);

	assert(sizeof(pid_t) == 4);
	socket->read_all(process_id);
	socket->read_all(parent_process_id);
	socket->read_all(process_group);

	std::stringstream ss;
	ss << "program name:\t" << "prog" << std::endl;
	ss << "trnsltn units:\t" << num_tus << std::endl;
	ss << "process id:\t" << process_id << std::endl;
	ss << "parent pid:\t" << parent_process_id << std::endl;
	ss << "process group:\t" << process_group << std::endl;

	glyphy_point_t cur_pos = { 0, 0 };
	demo_buffer_move_to(buffer, &cur_pos);

	demo_buffer_add_text(buffer, ss.str().c_str(), font, 2);

	demo_buffer_current_point(buffer, &cur_pos);
	double y_margin = cur_pos.y;

	cur_pos.x = 0;
	for (auto &current_unit : translation_units) {
		cur_pos.y = y_margin;

		uint64_t file_name_sz;
		socket->read_all(file_name_sz);

		current_unit.file_name.resize(file_name_sz);
		socket->read_all((uint8_t *)&current_unit.file_name[0], file_name_sz);

		read_file(current_unit.file_name, cur_pos);
		cur_pos.x += 50;

		socket->read_all(current_unit.num_lines);
		current_unit.execution_counts.resize(current_unit.num_lines, 0);

		socket->read_all(current_unit.inst_sites);
	}

	demo_font_print_stats(font);
}

void
RuntimeProcess::read_file(std::string file_name, glyphy_point_t top_left)
{
	std::string line;
	std::ifstream src_file(file_name, std::ios::binary);

	if (! src_file)
		errx(1, "src_file.open()");

	src_file.seekg(0, src_file.end);
	int length = src_file.tellg();
	src_file.seekg(0, src_file.beg);

	char *src_buffer = new char [length + 1];

	src_file.read(src_buffer, length);
	src_buffer[length] = '\0';

	if (! src_file)
		errx(1, "src_file.read()");
	src_file.close();

	demo_buffer_move_to(buffer, &top_left);
	demo_buffer_add_text(buffer, src_buffer, font, 1);

	delete[] src_buffer;
}

void
RuntimeProcess::draw()
{
}

void
RuntimeProcess::idle()
{
	for (auto &t : translation_units) {
		size_t bytes_total = t.num_lines * sizeof(uint64_t);

		socket->read_all((uint8_t *)&t.execution_counts[0], bytes_total);

		int execs = 0;
		for (int i = 0; i < t.num_lines; i++)
			execs += t.execution_counts[i];

		// std::cout << t.file_name << ": " << execs << std::endl;
	}

	// Send response back
	uint8_t msg_type = 1;
	assert(socket->write_all(&msg_type, 1) == 1);
}
