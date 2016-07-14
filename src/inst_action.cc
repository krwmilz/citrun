/*
 * Copyright (c) 2016 Kyle Milz <kyle@0x30.net>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */
#include <clang/Frontend/CompilerInstance.h>
#include <err.h>
#include <fstream>
#include <iostream>
#include <sstream>
#include <string>

#include "inst_action.h"
#include "runtime_h.h"

#if LLVM_VER > 35
std::unique_ptr<clang::ASTConsumer>
#else
clang::ASTConsumer *
#endif
InstrumentAction::CreateASTConsumer(clang::CompilerInstance &CI, clang::StringRef file)
{
	// llvm::errs() << "** Creating AST consumer for: " << file << "\n";
	clang::SourceManager &sm = CI.getSourceManager();
	TheRewriter.setSourceMgr(sm, CI.getLangOpts());

	// Hang onto a reference to this so we can read from it later
	InstrumentASTConsumer = new RewriteASTConsumer(TheRewriter);
#if LLVM_VER > 35
	return std::unique_ptr<clang::ASTConsumer>(InstrumentASTConsumer);
#else
	return InstrumentASTConsumer;
#endif
}

void
InstrumentAction::EndSourceFileAction()
{
	clang::SourceManager &sm = TheRewriter.getSourceMgr();
	const clang::FileID main_fid = sm.getMainFileID();
	// llvm::errs() << "** EndSourceFileAction for: "
	// 	<< sm.getFileEntryForID(main_fid)->getName()
	// 	<< "\n";

	clang::SourceLocation start = sm.getLocForStartOfFile(main_fid);
	clang::SourceLocation end = sm.getLocForEndOfFile(main_fid);
	unsigned int num_lines = sm.getPresumedLineNumber(end);

	std::string const file_name = getCurrentFile();
	std::stringstream ss;

	// Add preprocessor stuff so that the C runtime library links against
	// C++ object code.
	ss << "#ifdef __cplusplus" << std::endl;
	ss << "extern \"C\" {" << std::endl;
	ss << "#endif" << std::endl;

	// Embed the header directly in the primary source file.
	ss << runtime_h << std::endl;

	// Execution data needs to be big because it only increments.
	ss << "static uint64_t _citrun_lines[" << num_lines << "];" << std::endl;

	// Keep track of how many sites we instrumented.
	int rw_count = InstrumentASTConsumer->get_visitor().GetRewriteCount();

	// Define this translation units main book keeping data structure
	ss << "static struct citrun_node _citrun_node = {" << std::endl
		<< "	.lines_ptr = _citrun_lines," << std::endl
		<< "	.size = " << num_lines << "," << std::endl
		<< "	.inst_sites = " << rw_count << "," << std::endl
		<< "	.file_name = \"" << file_name << "\"," << std::endl;
	ss << "};" << std::endl;

	ss << "__attribute__((constructor))" << std::endl
		<< "static void citrun_constructor() {" << std::endl
		<< "	citrun_node_add(&_citrun_node);" << std::endl
		<< "}" << std::endl;

	// Close extern "C" {
	ss << "#ifdef __cplusplus" << std::endl;
	ss << "}" << std::endl;
	ss << "#endif" << std::endl;

	TheRewriter.InsertTextAfter(start, ss.str());

	llvm::StringRef file_ref(file_name);
	std::error_code ec;
	llvm::raw_fd_ostream output(file_ref, ec, llvm::sys::fs::F_None);

	// Write the instrumented source file
	TheRewriter.getEditBuffer(main_fid).write(output);
}
