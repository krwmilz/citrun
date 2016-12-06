#ifndef _INST_LOG_H
#define _INST_LOG_H

#include <iostream>
#include <llvm/Support/raw_ostream.h>
#include <llvm/Support/FileSystem.h>	// llvm::sys::fs::F_Append
#include <sstream>
#include <unistd.h>			// pid_t

//
// Taken from StackOverflow user Loki Astari. Thanks.
//
class InstrumentLogger : public std::ostream
{
	class LogBuffer : public std::stringbuf
	{
		pid_t			 m_pid;
		std::error_code		 m_ec;
		llvm::raw_fd_ostream	 m_outfile;
	public:
		bool			 m_iscitruninst;

		LogBuffer() :
			m_pid(getpid()),
			m_ec(),
			m_outfile("citrun.log", m_ec, llvm::sys::fs::F_Append),
			m_iscitruninst(false)
		{
			if (m_ec.value())
				std::cerr << "Can't open citrun.log: " << m_ec.message();
		}

		virtual int sync()
		{
			if (!m_ec.value()) {
				m_outfile << m_pid << ": " << str();
				m_outfile.flush();
			}

			if (m_iscitruninst)
				llvm::outs() << str();

			str("");
			return 0;
		}
	};

	LogBuffer buffer;
public:
	InstrumentLogger() :
		std::ostream(&buffer),
		buffer()
	{
	}

	void set_citruninst()
	{
		buffer.m_iscitruninst = true;
	}
};

#endif // _INST_LOG_H_
