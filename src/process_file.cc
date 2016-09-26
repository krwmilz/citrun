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
#include <sys/mman.h>		// mmap
#include <sys/stat.h>		// S_IRUSR

#include <cassert>
#include <csignal>		// kill
#include <err.h>
#include <fcntl.h>		// O_RDONLY
#include <fstream>
#include <stdlib.h>		// getenv
#include <unistd.h>		// getpagesize

#include "process_file.h"
#include "version.h"		// citrun_major


ProcessFile::ProcessFile(std::string const &path) :
	m_path(path),
	m_fd(0),
	m_mem(NULL),
	m_pos(0),
	m_tus_with_execs(0),
	m_program_loc(0)
{
	if ((m_fd = open(m_path.c_str(), O_RDONLY, S_IRUSR | S_IWUSR)) < 0)
		err(1, "open");

	struct stat sb;
	fstat(m_fd, &sb);

	if (sb.st_size > 1024 * 1024 * 1024)
		errx(1, "shared memory too large: %lli", sb.st_size);

	m_mem = (uint8_t *)mmap(NULL, sb.st_size, PROT_READ, MAP_SHARED, m_fd, 0);
	if (m_mem == MAP_FAILED)
		err(1, "mmap");

	m_size = sb.st_size;

	std::string magic;
	assert(sizeof(pid_t) == 4);

	shm_read_magic(magic);
	assert(magic == "citrun");
	shm_read_all(&m_major);
	assert(m_major == citrun_major);
	shm_read_all(&m_minor);
	shm_read_all(&m_pid);
	shm_read_all(&m_ppid);
	shm_read_all(&m_pgrp);
	shm_read_string(m_progname);
	shm_read_string(m_cwd);
	shm_next_page();

	while (shm_at_end() == false) {
		TranslationUnit t;

		shm_read_all(&t.num_lines);

		shm_read_string(t.comp_file_path);
		shm_read_string(t.abs_file_path);

		t.exec_counts = (uint64_t *)shm_get_block(t.num_lines * 8);
		t.exec_counts_last = new uint64_t[t.num_lines]();

		t.source.resize(t.num_lines);
		m_program_loc += t.num_lines;
		read_source(t);

		m_tus.push_back(t);

		shm_next_page();
	}
}

void
ProcessFile::read_source(struct TranslationUnit &t)
{
	std::ifstream file_stream(t.abs_file_path);

	if (file_stream.is_open() == 0) {
		warnx("ifstream.open(%s)", t.abs_file_path.c_str());
		return;
	}

	for (auto &l : t.source)
		std::getline(file_stream, l);
}

void
ProcessFile::shm_next_page()
{
	int page_size = getpagesize();
	m_pos += page_size - (m_pos % page_size);
}

void
ProcessFile::shm_read_magic(std::string &magic)
{
	magic.resize(6);

	memcpy(&magic[0], m_mem + m_pos, 6);
	m_pos += 6;
}

void
ProcessFile::shm_read_string(std::string &str)
{
	uint16_t len;

	memcpy(&len, m_mem + m_pos, sizeof(len));
	m_pos += sizeof(len);

	str.resize(len);
	memcpy(&str[0], m_mem + m_pos, len);
	m_pos += len;
}

void *
ProcessFile::shm_get_block(size_t inc)
{
	void *block = m_mem + m_pos;
	m_pos += inc;

	return block;
}

bool
ProcessFile::shm_at_end()
{
	assert(m_pos <= m_size);
	return (m_pos == m_size ? true : false);
}

bool
ProcessFile::is_alive() const
{
	if (kill(m_pid, 0) == 0)
		return 1;
	return 0;
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
ProcessFile::save_executions()
{
	for (auto &t : m_tus)
		memcpy(t.exec_counts_last, t.exec_counts, t.num_lines * 8);
}

void
ProcessFile::read_executions()
{
}
