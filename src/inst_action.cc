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
#include "inst_action.h"
#include "rt_h.h"
#include "version.h"		// citrun_major, citrun_minor

#include <clang/Frontend/CompilerInstance.h>
#include <err.h>
#include <fstream>
#include <sstream>
#include <string>


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
InstrumentAction::write_modified_src(clang::FileID const &fid)
{
	std::string out_file(getCurrentFile());

	if (m_is_citruninst) {
		out_file += ".citrun";
		*m_log << "Writing modified source to '" << out_file << "'" << std::endl;
	}

	std::error_code ec;
	llvm::raw_fd_ostream output(out_file, ec, llvm::sys::fs::F_None);
	if (ec.value()) {
		*m_log << "Error writing modified source '" << out_file
			<< "': " << ec.message() << std::endl;
		return;
	}

	// Write the instrumented source file
	m_TheRewriter.getEditBuffer(fid).write(output);
	*m_log << "Modified source written successfully." << std::endl;
}

void
InstrumentAction::EndSourceFileAction()
{
	clang::SourceManager &sm = m_TheRewriter.getSourceMgr();
	const clang::FileID main_fid = sm.getMainFileID();

	clang::SourceLocation end = sm.getLocForEndOfFile(main_fid);
	unsigned int num_lines = sm.getPresumedLineNumber(end);

	//
	// Write instrumentation preamble. Includes:
	// - runtime header,
	// - per tu citrun_node
	// - static constructor for runtime initialization
	//
	std::ostringstream preamble;
	preamble << "#ifdef __cplusplus\n"
		<< "extern \"C\" {\n"
		<< "#endif\n";
	preamble << rt_h;
	preamble << "static struct citrun_node _citrun = {\n"
		<< "	" << num_lines << ",\n"
		<< "	\"" << m_compiler_file_name << "\",\n"
		<< "	\"" << getCurrentFile().str() << "\",\n";
	preamble << "};\n";
	preamble << "__attribute__((constructor)) static void\n"
		<< "citrun_constructor() {\n"
		<< "	citrun_node_add(" << citrun_major << ", "
		<< citrun_minor << ", &_citrun);\n"
		<< "}\n";
	preamble << "#ifdef __cplusplus\n"
		<< "}\n"
		<< "#endif\n";

	clang::SourceLocation start = sm.getLocForStartOfFile(main_fid);
	if (m_TheRewriter.InsertTextAfter(start, preamble.str())) {
		*m_log << "Failed to insert the instrumentation preabmle.";
		return;
	}

	*m_log << "Instrumentation of '" << m_compiler_file_name << "' finished:" << std::endl;
	*m_log << "    " << num_lines << " Lines of source code" << std::endl;

	//
	// Write out statistics from the AST visitor.
	//
	RewriteASTVisitor v = m_InstrumentASTConsumer->get_visitor();
	for (int i = 0; i < NCOUNTERS; ++i) {
		if (v.m_counters[i] == 0)
			continue;
		*m_log << "    " << v.m_counters[i] << " "
			<< v.m_counter_descr[i] << std::endl;
	}

	write_modified_src(main_fid);
}
