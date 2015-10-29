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
class MyASTVisitor : public RecursiveASTVisitor<MyASTVisitor> {
public:
	MyASTVisitor(Rewriter &R) : TheRewriter(R) {}

	bool VisitVarDecl(VarDecl *d) {
		// std::cout << "HERE" << std::endl;
		return true;
	}

	bool VisitStmt(Stmt *s) {
		std::stringstream ss;
		SourceManager &SM = TheRewriter.getSourceMgr();
		unsigned line = SM.getPresumedLineNumber(s->getLocStart());

		ss << "lines[" << line << "] = 1";

		if (isa<IfStmt>(s)) {
			IfStmt *IfStatement = cast<IfStmt>(s);
			Stmt *Cond = IfStatement->getCond();
			ss << ", ";
			TheRewriter.InsertTextBefore(Cond->getLocStart(),
					ss.str());
		}
		else if (isa<ForStmt>(s)) {
			ForStmt *ForStatement = cast<ForStmt>(s);
			Stmt *Cond = ForStatement->getCond();
			ss << ", ";
			TheRewriter.InsertTextAfter(Cond->getLocStart(),
					ss.str());
		}
		else if (isa<ReturnStmt>(s)) {
			ReturnStmt *ReturnStatement = cast<ReturnStmt>(s);
			Expr *RetValue = ReturnStatement->getRetValue();
			ss << ", ";
			TheRewriter.InsertTextBefore(RetValue->getLocStart(),
					ss.str());
		}
		else if (isa<WhileStmt>(s)) {
			WhileStmt *WhileStatement = cast<WhileStmt>(s);
			Stmt *Cond = WhileStatement->getCond();
			ss << ", ";
			TheRewriter.InsertTextBefore(Cond->getLocStart(),
					ss.str());
		}
		else if (isa<BreakStmt>(s) || isa<ContinueStmt>(s) ||
		    isa<DeclStmt>(s) || isa<SwitchStmt>(s) ||
		    isa<SwitchCase>(s)) {
			ss << "; ";
			TheRewriter.InsertTextBefore(s->getLocStart(),
					ss.str());
		}
		else if (isa<CallExpr>(s)) {
			/* still has problems with f(x) + g(y) style code
			ss << ", ";
			TheRewriter.InsertTextBefore(s->getLocStart(),
					ss.str());
			*/
		}

		return true;
	}

	bool VisitFunctionDecl(FunctionDecl *f) {
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

private:
	Rewriter &TheRewriter;
};

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
	MyASTVisitor Visitor;
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
		// This isn't the correct size but will always be sufficient
		ss << "static unsigned int lines[" << sm.getFileIDSize(main_fid)
			<< "];\n";
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
