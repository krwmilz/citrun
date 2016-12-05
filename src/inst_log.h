#ifndef _INST_LOG_H
#define _INST_LOG_H

#include <iostream>
#include <llvm/Support/raw_ostream.h>
#include <llvm/Support/FileSystem.h>	// llvm::sys::fs::F_Append
#include <sstream>
#include <unistd.h>			// pid_t

class InstrumentLogger : public std::ostream
{
	class LogBuffer : public std::stringbuf
	{
		bool			 m_iscitruninst;
		pid_t			 m_pid;
		std::error_code		 m_ec;
		llvm::raw_fd_ostream	 m_outfile;
	public:
		LogBuffer(const bool &is_citruninst) :
			m_iscitruninst(is_citruninst),
			m_pid(getpid()),
			m_ec(),
			m_outfile("citrun.log", m_ec, llvm::sys::fs::F_Append)
		{
			if (m_ec.value())
			std::cerr << "Can't open citrun.log: " << m_ec.message();
		}

		virtual int sync()
		{
			m_outfile << m_pid << ": " << str();

			if (m_iscitruninst)
				llvm::outs() << str();

			str("");
			m_outfile.flush();
			return 0;
		}
	};

	LogBuffer buffer;
public:
	InstrumentLogger(const bool &is_citruninst) :
		std::ostream(&buffer),
		buffer(is_citruninst)
	{
	}
};

#endif // _INST_LOG_H_
