//
// Copyright (c) 2016 Kyle Milz <kyle@0x30.net>
//
// Permission to use, copy, modify, and distribute this software for any
// purpose with or without fee is hereby granted, provided that the above
// copyright notice and this permission notice appear in all copies.
//
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
// WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
// ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
// WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
// ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
// OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
//
#include <cassert>
#include <err.h>
#include <iostream>
#include <fstream>

#include "runtime_conn.h"

RuntimeProcess::RuntimeProcess(af_unix &sock) :
	socket(sock)
{
	uint64_t sz;
	uint64_t num_tus;
	uint64_t file_name_sz;
	assert(sizeof(pid_t) == 4);

	socket.read_all(sz);
	program_name.resize(sz);
	socket.read_all((uint8_t *)&program_name[0], sz);
	socket.read_all(num_tus);
	socket.read_all(lines_total);
	socket.read_all(process_id);
	socket.read_all(parent_process_id);
	socket.read_all(process_group);

	translation_units.resize(num_tus);
	for (auto &t : translation_units) {
		socket.read_all(file_name_sz);
		t.file_name.resize(file_name_sz);
		socket.read_all((uint8_t *)&t.file_name[0], file_name_sz);
		socket.read_all(t.num_lines);
		socket.read_all(t.inst_sites);

		t.execution_counts.resize(t.num_lines, 0);
		t.source.resize(t.num_lines);
		read_source(t);
	}
}

void
RuntimeProcess::read_source(struct TranslationUnit &t)
{
	std::string line;
	std::ifstream file_stream(t.file_name);

	if (file_stream.is_open() == 0)
		errx(1, "ifstream.open()");

	for (auto &l : t.source)
		std::getline(file_stream, l);
}

void
RuntimeProcess::read_executions()
{
	for (auto &t : translation_units) {
		size_t bytes_total = t.num_lines * sizeof(uint64_t);
		socket.read_all((uint8_t *)&t.execution_counts[0], bytes_total);
	}

	// Send response back
	uint8_t msg_type = 1;
	assert(socket.write_all(&msg_type, 1) == 1);
}
