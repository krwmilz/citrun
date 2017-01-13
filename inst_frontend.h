#include "inst_action.h"	// InstrumentAction
#include "inst_log.h"

#include <chrono>		// std::chrono::high_resolution_clock
#include <string>

class InstFrontend {
public:
	InstFrontend(int, char *argv[], bool);

	void			process_cmdline();
	void			instrument();
	void			compile_instrumented();

private:
	void			log_identity();
	void			clean_PATH();
	void			save_if_srcfile(char *);
	void			if_link_add_runtime(bool, bool);
	int			fork_compiler();
	void			exec_compiler();
	void			restore_original_src();

	std::vector<char *>	m_args;
	InstrumentLogger	m_log;
	bool			m_is_citruninst;
	std::string		m_compilers_path;
	std::string		m_lib_path;
	std::chrono::high_resolution_clock::time_point m_start_time;
	std::vector<std::string> m_source_files;
	std::map<std::string, std::string> m_temp_file_map;
};
