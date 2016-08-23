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
#include <csignal>		// kill
#include <err.h>
#include <fstream>

#include "process_file.h"
#include "version.h"		// citrun_major

ProcessFile::ProcessFile(std::string const &path) :
	m_shm(path),
	m_tus_with_execs(0),
	m_program_loc(0)
{
	assert(sizeof(pid_t) == 4);

	m_shm.read_all(&m_major);
	assert(m_major == citrun_major);
	m_shm.read_all(&m_minor);
	m_shm.read_all(&m_pid);
	m_shm.read_all(&m_ppid);
	m_shm.read_all(&m_pgrp);
	m_shm.read_cstring(&m_progname);
	m_shm.read_cstring(&m_cwd);
	m_shm.next_page();

	while (m_shm.at_end() == false) {
		TranslationUnit t;

		uint8_t ready;
		m_shm.read_all(&ready);

		m_shm.read_all(&t.num_lines);

		m_shm.read_cstring(&t.comp_file_path);
		m_shm.read_cstring(&t.abs_file_path);

		t.exec_diffs = (uint64_t *)m_shm.get_block(t.num_lines * 8);
		t.source.resize(t.num_lines);
		m_program_loc += t.num_lines;
		read_source(t);

		m_tus.push_back(t);

		m_shm.next_page();
	}
}

bool
ProcessFile::is_alive() const
{
	if (kill(m_pid, 0) == 0)
		return 1;
	return 0;
}


void
ProcessFile::read_source(struct TranslationUnit &t)
{
	std::ifstream file_stream(t.abs_file_path);

	if (file_stream.is_open() == 0) {
		warnx("ifstream.open(%s)", t.abs_file_path);
		return;
	}

	for (auto &l : t.source)
		std::getline(file_stream, l);
}

uint64_t
ProcessFile::total_execs()
{
	uint64_t count = 0;

	for (auto &t : m_tus)
		for (unsigned int i = 0; i < t.num_lines; ++i)
			count += t.exec_diffs[i];

	return count;
}

const TranslationUnit *
ProcessFile::find_tu(std::string const &srcname) const
{
	for (auto &i : m_tus)
		if (srcname == i.comp_file_path)
			return &i;
	return NULL;
}

void
ProcessFile::read_executions()
{
}
