#include "inst_log.h"

#include <iostream>
#include <llvm/Support/FileSystem.h>	// llvm::sys::fs::F_Append

InstrumentLogger::InstrumentLogger(const bool &is_citruninst) :
	m_iscitruninst(is_citruninst),
	m_needs_prefix(true),
	m_pid(getpid()),
	m_ec(),
	m_outfile("citrun.log", m_ec, llvm::sys::fs::F_Append)
{
	if (m_ec.value())
		std::cerr << "Can't open citrun.log: " << m_ec.message();
}

InstrumentLogger&
operator<<(InstrumentLogger& out, const char *rhs)
{
	if (out.m_ec.value())
		return out;

	out.print_prefix();
	out.m_outfile << rhs;
	if (out.m_iscitruninst)
		llvm::outs() << rhs;
	out.check_newline(rhs);

	return out;
}

void
InstrumentLogger::print_prefix()
{
	if (m_needs_prefix) {
		m_outfile << m_pid << ": ";
		m_needs_prefix = false;
	}
}

void
InstrumentLogger::check_newline(const std::string &rhs)
{
	if (std::find(rhs.begin(), rhs.end(), '\n') != rhs.end())
		m_needs_prefix = true;
}
