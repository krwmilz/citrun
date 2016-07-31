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

#include "runtime.hh"

RuntimeProcess::RuntimeProcess(af_unix &sock) :
	m_socket(sock),
	m_tus_with_execs(0)
{
	uint16_t sz;
	assert(sizeof(pid_t) == 4);

	// Protocol defined in lib/runtime.c send_static().
	// This is the receive side of things.
	m_socket.read_all(m_ver);
	m_socket.read_all(m_num_tus);
	m_socket.read_all(m_lines_total);
	m_socket.read_all(m_pid);
	m_socket.read_all(m_ppid);
	m_socket.read_all(m_pgrp);

	m_socket.read_all(sz);
	m_progname.resize(sz);
	m_socket.read_all((uint8_t *)&m_progname[0], sz);

	m_socket.read_all(sz);
	m_cwd.resize(sz);
	m_socket.read_all((uint8_t *)&m_cwd[0], sz);

	m_tus.resize(m_num_tus);
	for (auto &t : m_tus) {
		m_socket.read_all(sz);
		t.file_name.resize(sz);
		m_socket.read_all((uint8_t *)&t.file_name[0], sz);
		m_socket.read_all(t.num_lines);
		m_socket.read_all(t.inst_sites);

		t.exec_diffs.resize(t.num_lines, 0);
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
	m_tus_with_execs = 0;

	for (auto &t : m_tus) {
		m_socket.read_all(t.has_execs);

		if (t.has_execs == 0) {
			std::fill(t.exec_diffs.begin(), t.exec_diffs.end(), 0);
			continue;
		}

		m_tus_with_execs += 1;
		size_t bytes_total = t.num_lines * sizeof(uint32_t);
		m_socket.read_all((uint8_t *)&t.exec_diffs[0], bytes_total);
	}

	// Send response back
	uint8_t msg_type = 1;
	assert(m_socket.write_all(&msg_type, 1) == 1);
}