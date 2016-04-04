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
	ss << "Translation Units: " << num_tus << std::endl;
	ss << "Process ID: " << process_id << std::endl;
	ss << "Parent Process ID: " << parent_process_id << std::endl;
	ss << "Process Group: " << process_group << std::endl;

	glyphy_point_t top_left = { 0, 0 };
	demo_buffer_move_to(buffer, &top_left);
	demo_buffer_add_text(buffer, ss.str().c_str(), font, 1);

	for (auto &current_unit : translation_units) {
		top_left.y = 4;

		uint64_t file_name_sz;
		socket->read_all(file_name_sz);

		current_unit.file_name.resize(file_name_sz);
		socket->read_all((uint8_t *)&current_unit.file_name[0], file_name_sz);

		read_file(current_unit.file_name, top_left);
		top_left.x += 50;

		socket->read_all(current_unit.num_lines);
		current_unit.execution_counts.resize(current_unit.num_lines);

		socket->read_all(current_unit.inst_sites);
	}

	demo_font_print_stats(font);
}

void
RuntimeProcess::read_file(std::string file_name, glyphy_point_t top_left)
{
	std::string line;
	std::ifstream file_stream(file_name);

	if (file_stream.is_open() == 0)
		errx(1, "ifstream.open()");

	while (std::getline(file_stream, line)) {
		size_t tab_pos = 0;
		// Find and replace replace all tabs with spaces
		while ((tab_pos = line.find('\t')) != std::string::npos) {
			int rem = tab_pos % 8;
			line.erase(tab_pos, 1);
			line.insert(tab_pos, std::string(8 - rem, ' '));
		}

		demo_buffer_move_to(buffer, &top_left);
		demo_buffer_add_text(buffer, line.c_str(), font, 1);
		++top_left.y;
	}

	file_stream.close();
}

void
RuntimeProcess::draw()
{
}

void
RuntimeProcess::idle()
{
	for (auto &trans_unit : translation_units) {
		size_t bytes_total = trans_unit.num_lines * sizeof(uint64_t);
		assert(socket->read_all((uint8_t *)&trans_unit.execution_counts[0], bytes_total) == bytes_total);
	}

	// Send response back
	uint8_t msg_type = 1;
	assert(socket->write_all(&msg_type, 1) == 1);
}
