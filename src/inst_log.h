#ifndef __INST_LOG_H_
#define __INST_LOG_H_

#include <err.h>
#include <llvm/Support/raw_ostream.h>
#include <unistd.h>		// getpid

class InstrumentLogger {
public:
	InstrumentLogger() :
		m_pid(getpid()),
		m_needs_prefix(true)
	{};
	//~InstrumentLogger()
	//{ llvm::errs() << "~InstrumentLogger()\n"; };

	void set_output(const bool &is_citruninst) {

		if (is_citruninst) {
			m_output = &llvm::outs();
			return;
		} else {
			std::error_code ec;
			llvm::raw_fd_ostream *log_file =
				new llvm::raw_fd_ostream("citrun.log", ec, llvm::sys::fs::F_Append);

			if (ec.value()) {
				warnx("citrun.log: %s", ec.message().c_str());
				m_output = &llvm::nulls();
				return;
			}
			m_output = log_file;
		}

		//m_output = &output;
	};

	template <typename T>
	friend InstrumentLogger& operator<<(InstrumentLogger& out, const T &rhs)
	{
		out.print_prefix();
		*out.m_output << rhs;
		return out;
	}
	friend InstrumentLogger& operator<<(InstrumentLogger& out, const char *rhs)
	{
		out.print_prefix();
		*out.m_output << rhs;
		out.check_newline(rhs);
		return out;
	}

	pid_t			 m_pid;
	llvm::raw_ostream	*m_output;

private:
	void print_prefix() {
		if (m_needs_prefix) {
			*m_output << m_pid << ": ";
			m_needs_prefix = false;
		}
	};

	void check_newline(const std::string &rhs) {
		if (std::find(rhs.begin(), rhs.end(), '\n') != rhs.end())
			m_needs_prefix = true;
	};

	bool		 	 m_needs_prefix;
};

#endif // _INST_LOG_H_
