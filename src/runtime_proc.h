#ifndef TEXT_H
#define TEXT_H
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

class RuntimeProcess {
public:
	RuntimeProcess(shm &);
	void read_executions();

	uint8_t		 m_major;
	uint8_t		 m_minor;
	const char	*m_progname;
	const char	*m_cwd;
	uint32_t	 m_pid;
	pid_t		 m_ppid;
	pid_t		 m_pgrp;
	std::vector<TranslationUnit> m_tus;
	int		m_tus_with_execs;
private:
	void read_source(struct TranslationUnit &);

	shm m_shm;
};

#endif
