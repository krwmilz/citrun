#include <err.h>
#include <fcntl.h>	// open
#include <limits.h>
#include <sys/stat.h>	// mode flags
#include <unistd.h>	// getcwd, access

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

std::string
get_current_node(std::string const &file_path)
{
	size_t last_slash = file_path.find_last_of('/');
	std::string fn(file_path.substr(last_slash + 1));

	size_t period = fn.find_first_of('.');

	return fn.substr(0, period);
}

void
append_curr_node(std::string curr_node)
{
	char *cwd = getcwd(NULL, PATH_MAX);
	if (cwd == NULL)
		errx(1, "getcwd");

	std::string inst_filename(cwd);
	inst_filename.append("/INSTRUMENTED");

	// Append current primary source file to INSTRUMENTED list.
	std::ofstream inst_ofstream(inst_filename, std::ofstream::app);
	inst_ofstream << curr_node << std::endl;
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

	std::string file_name = getCurrentFile();
	std::string curr_node = get_current_node(file_name);
	append_curr_node(curr_node);

	std::stringstream ss;
	// Add preprocessor stuff so that the C runtime library links against
	// C++ object code.
	ss << "#ifdef __cplusplus" << std::endl;
	ss << "extern \"C\" {" << std::endl;
	ss << "#endif" << std::endl;

	// Embed the header directly in the primary source file.
	ss << runtime_h << std::endl;

	// Define storage for coverage data
	ss << "static uint64_t _citrun_lines[" << num_lines << "];" << std::endl;

	// Get visitor instance to check how many times it rewrote something
	RewriteASTVisitor visitor = InstrumentASTConsumer->get_visitor();

	// Define this translation units main book keeping data structure
	ss << "struct citrun_node citrun_node_" << curr_node << " = {" << std::endl
		<< "	.lines_ptr = _citrun_lines," << std::endl
		<< "	.size = " << num_lines << "," << std::endl
		<< "	.inst_sites = " << visitor.GetRewriteCount() << "," << std::endl
		<< "	.file_name = \"" << file_name << "\"," << std::endl;
	ss << "};" << std::endl;

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
