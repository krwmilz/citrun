#include <string>

#include "inst_action.h"	// InstrumentAction
#include "inst_log.h"

class CitrunInst {
public:
	CitrunInst(int, char *argv[], InstrumentLogger *, bool);

	void			clean_PATH();
	void			process_cmdline();
	int			instrument();
	int			compile_modified();

private:
	void			exec_compiler();
	int			fork_compiler();
	void			restore_original_src();
	void			save_if_srcfile(char *);
	int			try_unmodified_compile();

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
		return new InstrumentAction((llvm::raw_fd_ostream*)m_log->m_output, "", m_is_citruninst, m_source_files[m_i++]);
	}

private:
	InstrumentLogger	*m_log;
	bool			 m_is_citruninst;
	std::vector<std::string> m_source_files;
	int			 m_i;
};
