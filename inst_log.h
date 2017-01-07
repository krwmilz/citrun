#ifndef _INST_LOG_H
#define _INST_LOG_H

#include <llvm/Support/raw_ostream.h>
#include <llvm/Support/FileSystem.h>	// llvm::sys::fs::F_Append
#include <sstream>
#ifdef WIN32
#include <process.h>			// getpid
#else
#include <unistd.h>			// getpid
#endif

//
// Taken from StackOverflow user Loki Astari. Thanks.
//
class InstrumentLogger : public std::ostream
{
	class LogBuffer : public std::stringbuf
	{
		int			 m_pid;
		llvm::raw_ostream	*m_out;
	public:

		LogBuffer(bool is_citrun_inst) :
			m_pid(getpid())
		{
			if (is_citrun_inst) {
				m_out = &llvm::outs();
				return;
			}

			std::error_code m_ec;
			m_out = new llvm::raw_fd_ostream("citrun.log", m_ec, llvm::sys::fs::F_Append);
			if (m_ec.value()) {
				m_out = &llvm::errs();
				*m_out << "Can't open citrun.log: " << m_ec.message();
			}
		}

		virtual int sync()
		{
			*m_out << m_pid << ": " << str();
			m_out->flush();
			str("");

			return 0;
		}
	};

	LogBuffer buffer;
public:
	InstrumentLogger(bool is_citrun_inst) :
		std::ostream(&buffer),
		buffer(is_citrun_inst)
	{
	}
};

#endif // _INST_LOG_H_
