#ifndef __INST_LOG_H_
#define __INST_LOG_H_

#include <llvm/Support/raw_ostream.h>
#include <unistd.h>		// pid_t

class InstrumentLogger {
public:
	InstrumentLogger(const bool &);
	~InstrumentLogger();

	template <typename T>
	friend InstrumentLogger& operator<<(InstrumentLogger& out, const T &rhs)
	{
		out.print_prefix();
		*out.m_output << rhs;
		return out;
	}
	friend InstrumentLogger& operator<<(InstrumentLogger&, const char *);

	pid_t		 m_pid;
	llvm::raw_ostream *m_output;

private:
	void		 print_prefix();
	void		 check_newline(const std::string &);

	bool	 	 m_needs_prefix;
	bool		 m_delete;
};

#endif // _INST_LOG_H_
