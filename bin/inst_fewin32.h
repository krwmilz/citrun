#include "inst_fe.h"

class InstFrontendWin32 : public InstFrontend
{
	// Use InstFrontend's constructor
	using InstFrontend::InstFrontend;

	// Mandatory interface implementation.
	char		dir_sep();
	char		path_sep();
	std::string	lib_name();
	void		log_os_str();
	void		set_path(std::string const &);
	bool		is_link(bool, bool);
	void		copy_file(std::string const &, std::string const &);
	void		exec_compiler();
	int		fork_compiler();
};
