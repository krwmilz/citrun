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

bool
instrumenter::VisitVarDecl(VarDecl *d)
{
	// std::cout << "HERE" << std::endl;
	return true;
}

bool
instrumenter::VisitStmt(Stmt *s)
{
	std::stringstream ss;
	unsigned line = SM.getPresumedLineNumber(s->getLocStart());
	Stmt *stmt_to_inst = NULL;

	if (isa<IfStmt>(s)) {
		IfStmt *IfStatement = cast<IfStmt>(s);
		stmt_to_inst = IfStatement->getCond();
	}
	else if (isa<ForStmt>(s)) {
		ForStmt *ForStatement = cast<ForStmt>(s);
		stmt_to_inst = ForStatement->getCond();
	}
	else if (isa<WhileStmt>(s)) {
		WhileStmt *WhileStatement = cast<WhileStmt>(s);
		stmt_to_inst = WhileStatement->getCond();
	}
	else if (isa<SwitchStmt>(s)) {
		SwitchStmt *SwitchStatement = cast<SwitchStmt>(s);
		stmt_to_inst = SwitchStatement->getCond();
	}
	else if (isa<ReturnStmt>(s)) {
		ReturnStmt *ReturnStatement = cast<ReturnStmt>(s);
		stmt_to_inst = ReturnStatement->getRetValue();
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

	ss << "(++lines[" << line << "], ";
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
	if (f->hasBody()) {
#if 0
		Stmt *FuncBody = f->getBody();
		// Type name as string
		QualType QT = f->getReturnType();
		std::string TypeStr = QT.getAsString();

		// Function name
		DeclarationName DeclName = f->getNameInfo().getName();
		std::string FuncName = DeclName.getAsString();

		// Add comment before
		std::stringstream SSBefore;
		SSBefore << "// Begin function " << FuncName << " returning " << TypeStr
			<< "\n";
		SourceLocation ST = f->getSourceRange().getBegin();
		TheRewriter.InsertText(ST, SSBefore.str(), true, true);

		// And after
		std::stringstream SSAfter;
		SSAfter << "\n// End function " << FuncName;
		ST = FuncBody->getLocEnd().getLocWithOffset(1);
		TheRewriter.InsertText(ST, SSAfter.str(), true, true);
#endif
	}

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

	ss << "#include <scv_global.h>" << std::endl;
	// Define storage for coverage data
	ss << "static uint64_t lines[" << num_lines << "];" << std::endl;

	// Always declare this. The next TU will overwrite this or there won't
	// be a next TU.
	ss << "struct scv_node node" << tu_number + 1 << ";" << std::endl;

	// Define this translation units main book keeping data structure
	ss << "struct scv_node node" << tu_number << " = {" << std::endl
		<< "	.lines_ptr = lines," << std::endl
		<< "	.size = " << num_lines << "," << std::endl
		<< "	.file_name = \"" << file_name << "\"," << std::endl;
		ss << "	.next = &node" << tu_number + 1 << "," << std::endl;
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
