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


clang::ASTConsumer *
InstrumentAction::CreateASTConsumer(clang::CompilerInstance &CI, clang::StringRef file)
{
	// llvm::errs() << "** Creating AST consumer for: " << file << "\n";
	clang::SourceManager &sm = CI.getSourceManager();
	TheRewriter.setSourceMgr(sm, CI.getLangOpts());

	return new MyASTConsumer(TheRewriter);
}

unsigned int
read_src_number()
{
	char *cwd = getcwd(NULL, PATH_MAX);
	if (cwd == NULL)
		errx(1, "getcwd");

	std::string src_number_filename(cwd);
	src_number_filename.append("/SRC_NUMBER");

	if (access(src_number_filename.c_str(), F_OK) == -1) {
		// SRC_NUMBER does not exist, source number is 0
		return 0;
	}

	// SRC_NUMBER exists, read its content
	std::ifstream src_number_file;
	unsigned int src_num = 0;

	src_number_file.open(src_number_filename, std::fstream::in);
	src_number_file >> src_num;
	src_number_file.close();

	// Pre-increment. The current source number is the last one plus one
	return ++src_num;
}

void
write_src_number(int src_num)
{
	char *cwd = getcwd(NULL, PATH_MAX);
	if (cwd == NULL)
		errx(1, "getcwd");

	std::string src_number_filename(cwd);
	src_number_filename.append("/SRC_NUMBER");

	std::ofstream src_number_file;
	src_number_file.open(src_number_filename, std::fstream::out);
	src_number_file << src_num;
	src_number_file.close();
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
	unsigned int tu_number = read_src_number();

	std::stringstream ss;
	// Embed the header directly in the primary source file.
	ss << runtime_h << std::endl;

	// Define storage for coverage data
	ss << "static uint64_t _scv_lines[" << num_lines << "];" << std::endl;

	// Always declare this. The next TU will overwrite this or there won't
	// be a next TU.
	ss << "struct _scv_node _scv_node" << tu_number + 1 << ";" << std::endl;

	// Define this translation units main book keeping data structure
	ss << "struct _scv_node _scv_node" << tu_number << " = {" << std::endl
		<< "	.lines_ptr = _scv_lines," << std::endl
		<< "	.size = " << num_lines << "," << std::endl
		<< "	.file_name = \"" << file_name << "\"," << std::endl
		<< "	.next = &_scv_node" << tu_number + 1 << "," << std::endl
		<< "};" << std::endl;

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

	write_src_number(tu_number);
}
