#include <clang/AST/ASTConsumer.h>
#include <clang/Frontend/FrontendActions.h>
#include <clang/Rewrite/Core/Rewriter.h>

#include "rewrite_ast_visitor.h"

using namespace clang;

// For each source file provided to the tool, a new FrontendAction is created.
class InstrumentAction : public ASTFrontendAction {
public:
	InstrumentAction() {};

	void EndSourceFileAction() override;
	ASTConsumer *CreateASTConsumer(CompilerInstance &, StringRef) override;

private:
	Rewriter TheRewriter;
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
	RewriteASTVisitor Visitor;
};
