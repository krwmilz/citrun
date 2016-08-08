#ifndef TEXT_H
#define TEXT_H
#include <string>
#include <vector>

#include "af_unix.h"

struct TranslationUnit {
	std::string	file_name;
	uint32_t	num_lines;
	uint8_t		has_execs;
	std::vector<uint32_t> exec_diffs;
	std::vector<std::string> source;
};

class RuntimeProcess {
public:
	RuntimeProcess(af_unix &);
	void read_executions();

	// Protocol defined in lib/runtime.c send_static().
	uint8_t		m_major;
	uint8_t		m_minor;
	std::string	m_progname;
	std::string	m_cwd;
	uint32_t	m_num_tus;
	uint32_t	m_lines_total;
	pid_t		m_pid;
	pid_t		m_ppid;
	pid_t		m_pgrp;
	std::vector<TranslationUnit> m_tus;
	int		m_tus_with_execs;
private:
	void read_source(struct TranslationUnit &);

	af_unix m_socket;
};

#endif
