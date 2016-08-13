#include "inst_log.h"

#include <llvm/Support/FileSystem.h>	// llvm::sys::fs::F_Append
#include <err.h>

InstrumentLogger::InstrumentLogger(const bool &is_citruninst) :
	m_pid(getpid()),
	m_needs_prefix(true),
	m_delete(false)
{
	if (is_citruninst) {
		m_output = &llvm::outs();
	} else {
		std::error_code ec;
		m_output = new llvm::raw_fd_ostream("citrun.log", ec, llvm::sys::fs::F_Append);
		m_delete = true;

		if (ec.value()) {
			warnx("citrun.log: %s", ec.message().c_str());
			m_output = &llvm::nulls();
			m_delete = false;
		}
	}
}

InstrumentLogger::~InstrumentLogger()
{
	if (m_delete)
		delete m_output;
}

InstrumentLogger&
operator<<(InstrumentLogger& out, const char *rhs)
{
	out.print_prefix();
	*out.m_output << rhs;
	out.check_newline(rhs);

	return out;
}

void
InstrumentLogger::print_prefix()
{
	if (m_needs_prefix) {
		*m_output << m_pid << ": ";
		m_needs_prefix = false;
	}
}

void
InstrumentLogger::check_newline(const std::string &rhs)
{
	if (std::find(rhs.begin(), rhs.end(), '\n') != rhs.end())
		m_needs_prefix = true;
}
