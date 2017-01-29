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
#include <sys/stat.h>		// S_IRUSR, S_IWUSR

#include <err.h>
#include <fcntl.h>		// O_RDONLY
#include <unistd.h>		// getpagesize

#include "mem.h"		// Mem


class MemUnix : public Mem
{
	std::string	 m_path;
	int		 m_fd;

	// Mandatory implementation.
	size_t
	alloc_size()
	{
		return getpagesize();
	}

public:
	MemUnix(std::string const &path) :
		m_path(path),
		m_fd(0)
	{
		struct stat	 sb;

		if ((m_fd = open(m_path.c_str(), O_RDONLY, S_IRUSR | S_IWUSR)) < 0)
			err(1, "open");

		if (fstat(m_fd, &sb) < 0)
			err(1, "fstat");

		// Explicitly check 0 here otherwise mmap barfs.
		if (sb.st_size == 0 || sb.st_size > 1024 * 1024 * 1024)
			errx(1, "invalid file size %lli", sb.st_size);

		m_size = sb.st_size;

		m_base = mmap(NULL, sb.st_size, PROT_READ, MAP_SHARED, m_fd, 0);
		if (m_base == MAP_FAILED)
			err(1, "mmap");
	}
};
