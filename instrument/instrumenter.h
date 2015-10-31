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

using namespace clang;
using namespace clang::driver;
using namespace clang::tooling;


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
