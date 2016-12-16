#include <string>
#include <vector>

#include "gl_buffer.h"


//
// Owns a few pages of shared memory that are created by a running instrumented
// translation unit.
//
class TranslationUnit
{
	struct citrun_node	*m_node;
	uint64_t		*m_data;
	uint64_t		*m_data_buffer;

	std::vector<std::string> m_source;

public:
	TranslationUnit(void* &);

	std::string		 comp_file_path() const;
	unsigned int		 num_lines() const;
	void			 read_source();
	void			 save_executions();
};

//
// Owns an executing/executed instrumented processes shared memory file.
//
class ProcessFile
{
	struct citrun_header	*m_header;
	std::string		 m_path;
	int			 m_fd;
	size_t			 m_size;
	int			 m_tus_with_execs;
	unsigned int		 m_program_loc;
	GlBuffer		 m_glbuffer;

public:
	ProcessFile(std::string const &, demo_font_t *);

	const TranslationUnit	*find_tu(std::string const &) const;
	bool			 is_alive() const;
	void			 display();
	glyphy_extents_t	 get_extents();

	std::vector<TranslationUnit> m_tus;
};
