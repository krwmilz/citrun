#include <err.h>
#include <fcntl.h>	// open
#include <limits.h>
#include <sys/stat.h>	// mode flags
#include <unistd.h>	// getcwd, access

#include <fstream>
#include <iostream>
#include <sstream>
#include <string>

#include <clang/AST/AST.h>
#include <clang/Lex/Lexer.h>
#include <clang/Frontend/CompilerInstance.h>

#include "instrumenter.h"
#include "runtime_h.h"

bool
instrumenter::VisitVarDecl(VarDecl *d)
{
	return true;
}

bool
instrumenter::VisitStmt(Stmt *s)
{
	std::stringstream ss;
	unsigned line = SM.getPresumedLineNumber(s->getLocStart());
	Stmt *stmt_to_inst = NULL;

	if (isa<IfStmt>(s)) {
		stmt_to_inst = cast<IfStmt>(s)->getCond();
	}
	else if (isa<ForStmt>(s)) {
		stmt_to_inst = cast<ForStmt>(s)->getCond();
	}
	else if (isa<WhileStmt>(s)) {
		stmt_to_inst = cast<WhileStmt>(s)->getCond();
	}
	else if (isa<SwitchStmt>(s)) {
		stmt_to_inst = cast<SwitchStmt>(s)->getCond();
	}
	else if (isa<ReturnStmt>(s)) {
		stmt_to_inst = cast<ReturnStmt>(s)->getRetValue();
	}
	/*
	else if (isa<BreakStmt>(s) || isa<ContinueStmt>(s) ||
		|| isa<SwitchCase>(s)) {
	}
	*/
	else if (isa<DeclStmt>(s)) {
	}
	else if (isa<CallExpr>(s)) {
		stmt_to_inst = s;
	}

	if (stmt_to_inst == NULL)
		return true;

	ss << "(++_scv_lines[" << line << "], ";
	if (TheRewriter.InsertTextBefore(stmt_to_inst->getLocStart(), ss.str()))
		// writing failed, don't attempt to add ")"
		return true;

	TheRewriter.InsertTextAfter(real_loc_end(stmt_to_inst), ")");

	return true;
}

bool
instrumenter::VisitFunctionDecl(FunctionDecl *f)
{
	// Only function definitions (with bodies), not declarations.
	if (f->hasBody() == 0)
		return true;

	Stmt *FuncBody = f->getBody();

	DeclarationName DeclName = f->getNameInfo().getName();
	std::string FuncName = DeclName.getAsString();

	if (FuncName.compare("main") != 0)
		// Function is not main
		return true;

	std::stringstream ss;
	// On some platforms we need to depend directly on a symbol provided by
	// the runtime. Normally this isn't needed because the runtime only
	// depends on symbols in the isntrumented application.
	ss << "libscv_init();";
	SourceLocation curly_brace(FuncBody->getLocStart().getLocWithOffset(1));
	TheRewriter.InsertTextBefore(curly_brace, ss.str());

	return true;
}

SourceLocation
instrumenter::real_loc_end(Stmt *d)
{
	SourceLocation _e(d->getLocEnd());
	return SourceLocation(Lexer::getLocForEndOfToken(_e, 0, SM, lopt));
}

// MyFrontendAction ---

ASTConsumer *
MyFrontendAction::CreateASTConsumer(CompilerInstance &CI, StringRef file)
{
	// llvm::errs() << "** Creating AST consumer for: " << file << "\n";
	SourceManager &sm = CI.getSourceManager();
	TheRewriter.setSourceMgr(sm, CI.getLangOpts());

	return new MyASTConsumer(TheRewriter);
}

unsigned int
get_src_number()
{
	char *cwd = getcwd(NULL, PATH_MAX);
	if (cwd == NULL)
		errx(1, "getcwd");
	std::string src_number_filename(cwd);
	src_number_filename.append("/SRC_NUMBER");

	std::fstream src_number_file;
	if (access(src_number_filename.c_str(), F_OK) == -1) {
		// SRC_NUMBER does not exist, create it
		src_number_file.open(src_number_filename, std::fstream::out);
		src_number_file << 0;
		src_number_file.close();

		// First source file is zero
		return 0;
	}

	// SRC_NUMBER existed, read its contents and write incremented value
	src_number_file.open(src_number_filename, std::fstream::in | std::fstream::out);

	unsigned int src_num = 0;
	src_number_file >> src_num;
	++src_num;

	// Write the new source number
	src_number_file.seekg(0);
	src_number_file << src_num;

	return src_num;
}

void
MyFrontendAction::EndSourceFileAction()
{
	SourceManager &sm = TheRewriter.getSourceMgr();
	const FileID main_fid = sm.getMainFileID();
	// llvm::errs() << "** EndSourceFileAction for: "
	// 	<< sm.getFileEntryForID(main_fid)->getName()
	// 	<< "\n";

	SourceLocation start = sm.getLocForStartOfFile(main_fid);

	SourceLocation end = sm.getLocForEndOfFile(main_fid);
	unsigned int num_lines = sm.getPresumedLineNumber(end);

	std::string file_name = getCurrentFile();
	unsigned int tu_number = get_src_number();

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
		<< "	.file_name = \"" << file_name << "\"," << std::endl;
		ss << "	.next = &_scv_node" << tu_number + 1 << "," << std::endl;
	ss << "};" << std::endl;

	TheRewriter.InsertTextAfter(start, ss.str());

	// write the instrumented source file to another directory
	if (mkdir("inst", S_IWUSR | S_IRUSR | S_IXUSR))
		// already existing directory is ok
		if (errno != EEXIST)
			err(1, "mkdir");

	size_t last_slash = file_name.find_last_of('/');
	file_name.insert(last_slash + 1, "inst/");
	int fd = open(file_name.c_str(), O_WRONLY | O_CREAT,
			S_IRUSR | S_IWUSR);
	if (fd < 0)
		err(1, "open");
	llvm::raw_fd_ostream output(fd, /* close */ 1);
	TheRewriter.getEditBuffer(main_fid).write(output);
	// TheRewriter.getEditBuffer(main_fid).write(llvm::outs());
}
