//
// Instrument Frontend.
// Takes command lines and instruments source code.
//
#include "inst_log.h"

#include <chrono>		// std::chrono::high_resolution_clock
#include <map>			// std::map
#include <string>		// std::string

class InstFrontend
{
	void			save_if_srcfile(char *);
	void			restore_original_src();

	std::string		m_compilers_path;
	std::string		m_lib_path;
	std::chrono::high_resolution_clock::time_point m_start_time;
	std::map<std::string, std::string> m_temp_file_map;

	// Implemented by operating system specific classes.
	virtual void		log_os_str() = 0;
	virtual char		dir_sep() = 0;
	virtual char		path_sep() = 0;
	virtual std::string	lib_name() = 0;
	virtual void		set_path(std::string const &) = 0;
	virtual bool		is_link(bool, bool) = 0;
	virtual void		copy_file(std::string const &, std::string const &) = 0;
	virtual void		exec_compiler() = 0;
	virtual int		fork_compiler() = 0;

protected:
	std::vector<char *>	m_args;
	bool			m_is_citruninst;
	std::vector<std::string> m_source_files;
	InstrumentLogger	m_log;

public:
	InstFrontend(int, char *argv[], bool);

	void			log_identity();
	void			get_paths();
	void			clean_PATH();
	void			process_cmdline();
	void			instrument();
	void			compile_instrumented();
};

//
// Helper class that is a unary predicate suitable for use with std::find_if.
//
class ends_with
{
	std::string arg;
public:
	ends_with(char *argument) :
		arg(argument)
	{}

	bool operator ()(std::string const &suffix) const
	{
		if (suffix.length() > arg.length())
			return false;

		return std::equal(suffix.rbegin(), suffix.rend(), arg.rbegin());
	}
};
