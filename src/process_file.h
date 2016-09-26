#include <string>
#include <string.h>		// memcpy
#include <vector>


struct TranslationUnit {
	std::vector<std::string> source;
	std::string	 comp_file_path;
	std::string	 abs_file_path;
	uint64_t	*exec_counts;
	uint64_t	*exec_counts_last;
	uint32_t	 num_lines;
	uint8_t		 has_execs;
};

class ProcessFile {
private:
	void read_source(struct TranslationUnit &);

	template<typename T>
	void shm_read_all(T *buf)
	{
		memcpy(buf, m_mem + m_pos, sizeof(T));
		m_pos += sizeof(T);
	};

	void		 shm_next_page();
	void		 shm_read_string(std::string &);
	void		 shm_read_magic(std::string &);
	void		*shm_get_block(size_t);
	bool		 shm_at_end();

	std::string	 m_path;
	int		 m_fd;
	uint8_t		*m_mem;
	size_t		 m_pos;
	size_t		 m_size;

public:
	ProcessFile(std::string const &);

	const TranslationUnit *find_tu(std::string const &) const;
	bool		 is_alive() const;
	void		 read_executions();
	void		 save_executions();

	uint8_t		 m_major;
	uint8_t		 m_minor;
	std::string	 m_progname;
	std::string	 m_cwd;
	uint32_t	 m_pid;
	uint32_t	 m_ppid;
	uint32_t	 m_pgrp;
	std::vector<TranslationUnit> m_tus;
	int		 m_tus_with_execs;

	uint32_t	 m_program_loc;
};
