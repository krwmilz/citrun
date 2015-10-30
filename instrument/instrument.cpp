//------------------------------------------------------------------------------
// Tooling sample. Demonstrates:
//
// * How to write a simple source tool using libTooling.
// * How to use RecursiveASTVisitor to find interesting AST nodes.
// * How to use the Rewriter API to rewrite the source code.
//
// Eli Bendersky (eliben@gmail.com)
// This code is in the public domain
//------------------------------------------------------------------------------
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

static llvm::cl::OptionCategory ToolingSampleCategory("Tooling Sample");


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
	Stmt *stmt_to_inst;

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
	else
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
	MyFrontendAction() {}
	void EndSourceFileAction() override {
		SourceManager &sm = TheRewriter.getSourceMgr();
		const FileID main_fid = sm.getMainFileID();
		// llvm::errs() << "** EndSourceFileAction for: "
		// 	<< sm.getFileEntryForID(main_fid)->getName()
		// 	<< "\n";

		SourceLocation start = sm.getLocForStartOfFile(main_fid);

		std::stringstream ss;
		// This isn't the number of lines but rather bytes
		int file_bytes = sm.getFileIDSize(main_fid);
		ss << "unsigned int lines[" << file_bytes << "];"
			<< std::endl;
		ss << "int size = " << file_bytes << ";" << std::endl;
		TheRewriter.InsertTextAfter(start, ss.str());

		// Now emit the rewritten buffer.
		TheRewriter.getEditBuffer(main_fid).write(llvm::outs());
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
};

int
main(int argc, const char *argv[])
{
	CommonOptionsParser op(argc, argv, ToolingSampleCategory);
	ClangTool Tool(op.getCompilations(), op.getSourcePathList());

	// ClangTool::run accepts a FrontendActionFactory, which is then used to
	// create new objects implementing the FrontendAction interface. Here we
	// use the helper newFrontendActionFactory to create a default factory
	// that will return a new MyFrontendAction object every time.  To
	// further customize this, we could create our own factory class.
	return Tool.run(newFrontendActionFactory<MyFrontendAction>());
}
