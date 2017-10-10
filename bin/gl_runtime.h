//
// Copyright (c) 2017 Kyle Milz <kyle.milz@gmail.com>
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
#include <sys/types.h>

#include <dirent.h>		// DIR, opendir, readdir
#include <string>		// std::string
#include <unordered_set>	// std::unordered_set
#include <vector>		// std::vector

#include "gl_buffer.h"		// citrun::gl_buffer
#include "gl_font.h"		// citrun::gl_font
#include "mem.h"		// citrun::mem
#ifdef _WIN32
#include "mem_win32.h"
#else
#include "mem_unix.h"		// citrun::mem_unix
#endif


namespace citrun {

//
// Owns a few pages of shared memory and a gl buffer.
//
class gl_transunit {
private:
	struct citrun_node	*m_node;
	uint64_t		*m_data;
	std::vector<uint64_t>	 m_data_buffer;
	citrun::gl_buffer	 m_glbuffer;

public:
	gl_transunit(citrun::mem &, citrun::gl_font &, glyphy_point_t &);

	std::string		 comp_file_path() const;
	unsigned int		 num_lines() const;
	void			 save_executions();
	void			 display();
	glyphy_extents_t	 get_extents();
};

//
// Owns an executing/executed instrumented processes shared memory file and
// gl_buffer.
//
class gl_procfile {
private:
	struct citrun_header	*m_header;
	citrun::gl_buffer	 m_glbuffer;
#ifdef _WIN32
	MemWin32		 m_mem;
#else
	citrun::mem_unix	 m_mem;
#endif

public:
	gl_procfile(std::string const&, citrun::gl_font &, double const&);

	const citrun::gl_transunit *find_tu(std::string const &) const;
	bool			 is_alive() const;
	void			 display();
	glyphy_extents_t	 get_extents();

	std::vector<citrun::gl_transunit> m_tus;
};

class process_dir {
private:
	const char			*m_procdir;
	DIR				*m_dirp;
	std::unordered_set<std::string>	 m_known_files;

public:
	process_dir();
	std::vector<std::string>	 scan();
};

} // namespace citrun
