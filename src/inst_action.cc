//
// Copyright (c) 2016 Kyle Milz <kyle@0x30.net>
//
// Permission to use, copy, modify, and distribute this software for any
// purpose with or without fee is hereby granted, provided that the above
// copyright notice and this permission notice appear in all copies.
//
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
// WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
// ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
// WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
// ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
// OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
//
#include <clang/Frontend/CompilerInstance.h>
#include <err.h>
#include <fstream>
#include <sstream>
#include <string>

#include "inst_action.h"
#include "runtime_h.h"

std::unique_ptr<clang::ASTConsumer>
InstrumentAction::CreateASTConsumer(clang::CompilerInstance &CI, clang::StringRef file)
{
	// llvm::errs() << "** Creating AST consumer for: " << file << "\n";
	clang::SourceManager &sm = CI.getSourceManager();
	m_TheRewriter.setSourceMgr(sm, CI.getLangOpts());

	// Hang onto a reference to this so we can read from it later
	m_InstrumentASTConsumer = new RewriteASTConsumer(m_TheRewriter);
	return std::unique_ptr<clang::ASTConsumer>(m_InstrumentASTConsumer);
}

void
InstrumentAction::EndSourceFileAction()
{
	clang::SourceManager &sm = m_TheRewriter.getSourceMgr();
	const clang::FileID main_fid = sm.getMainFileID();

	clang::SourceLocation start = sm.getLocForStartOfFile(main_fid);
	clang::SourceLocation end = sm.getLocForEndOfFile(main_fid);
	unsigned int num_lines = sm.getPresumedLineNumber(end);

	std::string const file_name = getCurrentFile();

	// Write instrumentation preamble. Includes runtime header, per tu
	// citrun_node and static constructor for runtime initialization.
	std::stringstream ss;
	ss << "#ifdef __cplusplus" << std::endl
		<< "extern \"C\" {" << std::endl
		<< "#endif" << std::endl;
	ss << runtime_h << std::endl;
	ss << "static uint64_t _citrun_lines[" << num_lines << "];" << std::endl;
	ss << "static struct citrun_node _citrun_node = {" << std::endl
		<< "	_citrun_lines," << std::endl
		<< "	" << num_lines << "," << std::endl
		<< "	\"" << m_compiler_file_name << "\"," << std::endl
		<< "	\"" << file_name << "\"," << std::endl;
	ss << "};" << std::endl;
	ss << "__attribute__((constructor))" << std::endl
		<< "static void citrun_constructor() {" << std::endl
		<< "	citrun_node_add(citrun_major, citrun_minor, &_citrun_node);" << std::endl
		<< "}" << std::endl;
	ss << "#ifdef __cplusplus" << std::endl
		<< "}" << std::endl
		<< "#endif" << std::endl;

	std::string header = ss.str();
	unsigned header_sz = std::count(header.begin(), header.end(), '\n');

	if (!m_is_citruninst && m_TheRewriter.InsertTextAfter(start, header)) {
		*m_log << m_pfx << "Failed inserting " << header_sz
			<< " lines of instrumentation preabmle.";
		return;
	}

	*m_log << m_pfx << "Instrumentation of '" << m_compiler_file_name << "' finished:\n";
	*m_log << m_pfx << "    " << num_lines << " Lines of source code\n";
	*m_log << m_pfx << "    " << header_sz << " Lines of instrumentation header\n";

	//
	// Write out statistics from the AST visitor.
	//
	RewriteASTVisitor v = m_InstrumentASTConsumer->get_visitor();
	for (int i = 0; i < 9; i++) {
		if (v.m_counters[i] == 0)
			continue;
		*m_log << m_pfx << "    " << v.m_counters[i] << " "
			<< v.m_counter_descr[i] << "\n";
	}

	std::string out_file(file_name);
	if (m_is_citruninst) {
		out_file = file_name + ".citrun";
		*m_log << m_pfx << "Writing modified source to '"
			<< out_file << "'.\n";
	}

	std::error_code ec;
	llvm::raw_fd_ostream output(out_file, ec, llvm::sys::fs::F_None);
	if (ec.value()) {
		*m_log << m_pfx << "Error writing modified source: "
			<< ec.message() << "\n";
		warnx("'%s': %s", file_name.c_str(), ec.message().c_str());
		return;
	}

	// Write the instrumented source file
	m_TheRewriter.getEditBuffer(main_fid).write(output);
	*m_log << m_pfx << "Modified source written successfully.\n";
}
