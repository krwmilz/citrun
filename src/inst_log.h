#ifndef _INST_LOG_H
#define _INST_LOG_H

#include <llvm/Support/raw_ostream.h>
#include <unistd.h>		// pid_t

class InstrumentLogger {
private:
	void		 	 print_prefix();
	void		 	 check_newline(const std::string &);

	bool			 m_iscitruninst;
	bool	 	 	 m_needs_prefix;

public:
	InstrumentLogger(const bool &);

	template <typename T>
	friend InstrumentLogger& operator<<(InstrumentLogger& out, const T &rhs)
	{
		if (out.m_ec.value())
			return out;

		out.print_prefix();
		out.m_outfile << rhs;
		if (out.m_iscitruninst)
			llvm::outs() << rhs;
		return out;
	}
	friend InstrumentLogger& operator<<(InstrumentLogger&, const char *);

	pid_t			 m_pid;
	std::error_code		 m_ec;
	llvm::raw_fd_ostream	 m_outfile;
};

#endif // _INST_LOG_H_
