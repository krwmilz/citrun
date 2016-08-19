#include "inst_action.h"	// InstrumentAction
#include "inst_log.h"

#include <string>

class InstrumentFrontend {
public:
	InstrumentFrontend(int, char *argv[], InstrumentLogger *, bool);

	void			process_cmdline();
	int			instrument();
	int			fork_compiler();
	void			exec_compiler();
	void			restore_original_src();

private:
	void			save_if_srcfile(char *);
	void			if_link_add_runtime(bool, bool);

	std::vector<char *>	m_args;
	InstrumentLogger	*m_log;
	bool			m_is_citruninst;
	std::vector<std::string> m_source_files;
	std::map<std::string, std::string> m_temp_file_map;
};

//
// Needed because we pass custom stuff down into the ASTFrontendAction
//
class InstrumentActionFactory : public clang::tooling::FrontendActionFactory {
public:
	InstrumentActionFactory(InstrumentLogger *log, bool citruninst,
			std::vector<std::string> const &src_files) :
		m_log(log),
		m_is_citruninst(citruninst),
		m_source_files(src_files),
		m_i(0)
	{};

	clang::ASTFrontendAction *create() {
		return new InstrumentAction(m_log, m_is_citruninst, m_source_files[m_i++]);
	}

private:
	InstrumentLogger	*m_log;
	bool			 m_is_citruninst;
	std::vector<std::string> m_source_files;
	int			 m_i;
};
