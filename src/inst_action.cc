#include <err.h>
#include <fcntl.h>	// open
#include <limits.h>
#include <sys/stat.h>	// mode flags

#include <fstream>
#include <iostream>
#include <sstream>
#include <string>

#include <clang/Frontend/CompilerInstance.h>

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

	int fd = open(file_name.c_str(), O_WRONLY | O_CREAT, S_IRUSR | S_IWUSR);
	if (fd < 0)
		err(1, "open");
	llvm::raw_fd_ostream output(fd, /* close */ 1);

	// Write the instrumented source file
	TheRewriter.getEditBuffer(main_fid).write(output);
}
