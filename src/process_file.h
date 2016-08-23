#include <string>
#include <vector>

#include "shm.h"

struct TranslationUnit {
	const char	*comp_file_path;
	const char	*abs_file_path;
	uint32_t	 num_lines;
	uint8_t		 has_execs;
	uint64_t	*exec_diffs;
	std::vector<std::string> source;
};

class ProcessFile {
private:
	void read_source(struct TranslationUnit &);

	Shm m_shm;
public:
	ProcessFile(std::string const &);

	const TranslationUnit *find_tu(std::string const &) const;
	uint64_t total_execs();
	bool		 is_alive() const;
	void read_executions();

	uint8_t		 m_major;
	uint8_t		 m_minor;
	const char	*m_progname;
	const char	*m_cwd;
	uint32_t	 m_pid;
	uint32_t	 m_ppid;
	uint32_t	 m_pgrp;
	std::vector<TranslationUnit> m_tus;
	int		 m_tus_with_execs;

	uint32_t	 m_program_loc;
};
