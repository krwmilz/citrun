#include <err.h>	// err, errx
#include <fcntl.h>	// open
#include <stdlib.h>	// mktemp
#include <unistd.h>
#include <sys/stat.h>	// mode flags

#include <sstream>
#include <string>
#include <iostream>

#include "clang/AST/AST.h"
#include "clang/AST/ASTConsumer.h"
#include "clang/AST/RecursiveASTVisitor.h"
#include "clang/Frontend/ASTConsumers.h"
#include "clang/Frontend/FrontendActions.h"
#include "clang/Frontend/CompilerInstance.h"
#include "clang/Lex/Lexer.h"
#include "clang/Tooling/CommonOptionsParser.h"
#include "clang/Tooling/Tooling.h"
#include "clang/Rewrite/Core/Rewriter.h"
#include "llvm/Support/raw_ostream.h"

using namespace clang;
using namespace clang::driver;
using namespace clang::tooling;

static llvm::cl::OptionCategory ToolingCategory("instrument options");


// By implementing RecursiveASTVisitor, we can specify which AST nodes
// we're interested in by overriding relevant methods.
class instrumenter : public RecursiveASTVisitor<instrumenter> {
public:
	instrumenter(Rewriter &R) : TheRewriter(R), SM(R.getSourceMgr()) {}


	bool VisitVarDecl(VarDecl *d);
	bool VisitStmt(Stmt *s);
	bool VisitFunctionDecl(FunctionDecl *f);

private:
	Rewriter &TheRewriter;
	SourceManager &SM;
	LangOptions lopt;

	SourceLocation real_loc_end(Stmt *s);
};

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
	else if (isa<ReturnStmt>(s)) {
		ReturnStmt *ReturnStatement = cast<ReturnStmt>(s);
		stmt_to_inst = ReturnStatement->getRetValue();
	}
	/*
	else if (isa<BreakStmt>(s) || isa<ContinueStmt>(s) ||
		|| isa<SwitchStmt>(s) || isa<SwitchCase>(s)) {
	}
	*/
	else if (isa<DeclStmt>(s)) {
	}
	else if (isa<CallExpr>(s)) {
		stmt_to_inst = s;
	}

	if (stmt_to_inst == NULL)
		return true;

	ss << "(lines[" << line << "] = 1, ";
	TheRewriter.InsertTextBefore(stmt_to_inst->getLocStart(), ss.str());
	TheRewriter.InsertTextAfter(real_loc_end(stmt_to_inst), ")");

	return true;
}

bool
instrumenter::VisitFunctionDecl(FunctionDecl *f)
{
	// Only function definitions (with bodies), not declarations.
	if (f->hasBody()) {
		Stmt *FuncBody = f->getBody();
#if 0
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


// Implementation of the ASTConsumer interface for reading an AST produced
// by the Clang parser.
class MyASTConsumer : public ASTConsumer {
public:
	MyASTConsumer(Rewriter &R) : Visitor(R) {}

	// Override the method that gets called for each parsed top-level
	// declaration.
	bool HandleTopLevelDecl(DeclGroupRef DR) override {
		for (DeclGroupRef::iterator b = DR.begin(), e = DR.end(); b != e; ++b) {
			// Traverse the declaration using our AST visitor.
			Visitor.TraverseDecl(*b);
			// (*b)->dump();
		}
		return true;
	}

private:
	instrumenter Visitor;
};

// For each source file provided to the tool, a new FrontendAction is created.
class MyFrontendAction : public ASTFrontendAction {
public:
	MyFrontendAction(std::vector<const char *> &);
	void EndSourceFileAction() override {
		SourceManager &sm = TheRewriter.getSourceMgr();
		const FileID main_fid = sm.getMainFileID();
		// llvm::errs() << "** EndSourceFileAction for: "
		// 	<< sm.getFileEntryForID(main_fid)->getName()
		// 	<< "\n";

		SourceLocation start = sm.getLocForStartOfFile(main_fid);

		std::stringstream ss;
		// Add declarations for coverage buffers
		int file_bytes = sm.getFileIDSize(main_fid);
		ss << "unsigned int lines[" << file_bytes << "];"
			<< std::endl;
		ss << "int size = " << file_bytes << ";" << std::endl;
		TheRewriter.InsertTextAfter(start, ss.str());

		// Now emit the rewritten buffer.
		// std::ofstream output(inst_files[0]);
		int fd = open(inst_files[0], O_WRONLY | O_CREAT, S_IRUSR | S_IWUSR);
		if (fd < 0)
			err(1, "open");
		llvm::raw_fd_ostream output(fd, /* close */ 1);
		TheRewriter.getEditBuffer(main_fid).write(output);
		// TheRewriter.getEditBuffer(main_fid).write(llvm::outs());
	}

	ASTConsumer *CreateASTConsumer(CompilerInstance &CI,
			StringRef file) override {
		// llvm::errs() << "** Creating AST consumer for: " << file << "\n";
		SourceManager &sm = CI.getSourceManager();
		TheRewriter.setSourceMgr(sm, CI.getLangOpts());

		return new MyASTConsumer(TheRewriter);
	}

private:
	Rewriter TheRewriter;

	std::vector<const char *> inst_files;
};

MyFrontendAction::MyFrontendAction(std::vector<const char *> &i) :
	inst_files(i)
{
}

class MFAF : public FrontendActionFactory {
public:
	MFAF(std::vector<const char *> &i) : inst_files(i) {}

	FrontendAction *create() {
		return new MyFrontendAction(inst_files);
	}

private:
	std::vector<const char *> inst_files;
};

void
clean_path()
{
	// remove SCV_PATH from PATH

	char *scv_path = getenv("SCV_PATH");
	char *path = getenv("PATH");
	if (scv_path == NULL)
		errx(1, "SCV_PATH not found in environment, not running "
			"native compiler");
	else if (path == NULL)
		errx(1, "PATH not set, your build system needs to use "
			"the PATH for this tool to be useful.");
#ifdef DEBUG
	std::cout << "SCV_PATH=" << scv_path << std::endl;
	std::cout << "old PATH=" << path << std::endl;
#endif

	int new_path_pos = 0;
	char *new_path = (char *)calloc(strlen(path), 1);

	char *tok = strtok(path, ":");
	bool wrote_first_token = false;
	while (tok != NULL) {
		if (strncmp(scv_path, tok, 1024) != 0) {
			// didn't find SCV_PATH in PATH
			if (wrote_first_token == true) {
				strcat(new_path + new_path_pos, ":");
				new_path_pos++;
			}
			strcat(new_path + new_path_pos, tok);
			new_path_pos += strlen(tok);
			wrote_first_token = true;
		}
		tok = strtok(NULL, ":");
	}

	setenv("PATH", new_path, 1);
#ifdef DEBUG
	std::cout << "new " << new_path << std::endl;
	system("env");
#endif
}

void
instrument(int argc, char *argv[], std::vector<const char *> &source_files,
		std::vector<const char *> &inst_files)
{
	const char *clang_argv[source_files.size() + 1 + argc];
	int clang_argc = 0;

	clang_argv[clang_argc++] = argv[0];
	for (auto s : source_files)
		clang_argv[clang_argc++] = s;

	clang_argv[clang_argc++] = "--";

	// append original command line verbatim after --
	for (int i = 0; i < argc; i++)
		clang_argv[clang_argc++] = argv[i];

#ifdef DEBUG
	// print out
	for (int i = 0; i < clang_argc; i++)
		std::cout << clang_argv[i] << " ";
	std::cout << std::endl;
#endif

	// give clang it's <source files> -- <native command line> arg style
	CommonOptionsParser op(clang_argc, clang_argv, ToolingCategory);
	ClangTool Tool(op.getCompilations(), op.getSourcePathList());

	// ClangTool::run accepts a FrontendActionFactory, which is then used to
	// create new objects implementing the FrontendAction interface. Here we
	// use the helper newFrontendActionFactory to create a default factory
	// that will return a new MyFrontendAction object every time.  To
	// further customize this, we could create our own factory class.
	int ret = Tool.run(new MFAF(inst_files));
	// int ret = Tool.run(newFrontendActionFactory<MyFrontendAction>());
	if (ret)
		errx(1, "Instrumentation failed");
}

int
main(int argc, char *argv[])
{
	std::vector<const char *> source_files;
	std::vector<const char *> inst_files;
	char *exec_argv[argc + 1];

	for (int i = 0; i < argc; i++) {
		exec_argv[i] = strdup(argv[i]);

		int arg_len = strlen(argv[i]);
		if (arg_len < 4)
			continue;

		// compare last four bytes of argument
		if (strcmp(argv[i] + arg_len - 4, ".cpp") == 0 ||
		    strcmp(argv[i] + arg_len - 2, ".c") == 0) {
			// keep track of original source file names
			source_files.push_back(argv[i]);

			char *inst_filename = (char *)calloc(PATH_MAX, 1);
			if (inst_filename == NULL)
				err(1, "calloc");

			strncpy(inst_filename, argv[i], arg_len - 2);
			strcat(inst_filename, "_inst.c");

			// source code rewriter needs to know this file
			inst_files.push_back(inst_filename);
			// native compiler uses this source file instead
			exec_argv[i] = inst_filename;
		}
	}
	// very important that argv passed to execvp is NULL terminated
	exec_argv[argc] = NULL;

	// run native command if there's no source files to instrument
	if (source_files.size() == 0) {
		warnx("no source files found on command line");

		clean_path();
		if (execvp(exec_argv[0], exec_argv))
			err(1, "execvp");
	}

	// run instrumentation on detected source files
	instrument(argc, argv, source_files, inst_files);

#if DEBUG
	std::cout << "Calling real compiler " << exec_argv[0] << std::endl;
#endif

	// exec native compiler with instrumented source files
	clean_path();
	if (execvp(exec_argv[0], exec_argv))
		err(1, "execvp");
}
