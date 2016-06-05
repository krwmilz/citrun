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

#include "instrument_action.h"
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
get_current_node(std::string file_path)
{
	size_t last_slash = file_path.find_last_of('/');
	std::string fn(file_path.substr(last_slash + 1));

	std::replace(fn.begin(), fn.end(), '.', '_');
	std::replace(fn.begin(), fn.end(), '-', '_');

	return fn;
}

std::string
swap_last_node(std::string curr_node)
{
	char *cwd = getcwd(NULL, PATH_MAX);
	if (cwd == NULL)
		errx(1, "getcwd");

	std::string src_number_filename(cwd);
	src_number_filename.append("/LAST_NODE");

	std::string last_node("NULL");

	if (access(src_number_filename.c_str(), F_OK) == 0) {
		// LAST_NODE exists, read last_node from file
		std::ifstream src_number_file;
		src_number_file.open(src_number_filename, std::fstream::in);
		src_number_file >> last_node;
		src_number_file.close();
	}

	// Always write curr_node to file
	std::ofstream src_number_file;
	src_number_file.open(src_number_filename, std::fstream::out);
	src_number_file << curr_node;
	src_number_file.close();

	return last_node;
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
	std::string last_node = swap_last_node(curr_node);

	//std::cerr << "LAST NODE = " << last_node << std::endl;

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

	// Let the struct know this definition will be elsewhere
	ss << "extern struct _citrun_node _citrun_node_" << last_node << ";" << std::endl;

	// Define this translation units main book keeping data structure
	ss << "struct _citrun_node _citrun_node_" << curr_node << " = {" << std::endl
		<< "	.lines_ptr = _citrun_lines," << std::endl
		<< "	.size = " << num_lines << "," << std::endl
		<< "	.inst_sites = " << visitor.GetRewriteCount() << "," << std::endl
		<< "	.file_name = \"" << file_name << "\"," << std::endl;
	if (last_node.compare("NULL") == 0)
		ss << "	.next = NULL," << std::endl;
	else
		ss << "	.next = &_citrun_node_" << last_node << "," << std::endl;
	ss << "};" << std::endl;

	// Close extern "C" {
	ss << "#ifdef __cplusplus" << std::endl;
	ss << "}" << std::endl;
	ss << "#endif" << std::endl;

	TheRewriter.InsertTextAfter(start, ss.str());

	size_t last_slash = file_name.find_last_of('/');
	std::string base_dir(file_name.substr(0, last_slash + 1));
	base_dir.append("inst");

	if (mkdir(base_dir.c_str(), S_IWUSR | S_IRUSR | S_IXUSR))
		if (errno != EEXIST)
			// An error other than the directory existing occurred
			err(1, "mkdir");

	file_name.insert(last_slash + 1, "inst/");

	// Instrumented source file might already exist
	unlink(file_name.c_str());

	int fd = open(file_name.c_str(), O_WRONLY | O_CREAT, S_IRUSR | S_IWUSR);
	if (fd < 0)
		err(1, "open");
	llvm::raw_fd_ostream output(fd, /* close */ 1);

	// Write the instrumented source file
	TheRewriter.getEditBuffer(main_fid).write(output);
}
