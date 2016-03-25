#include <clang/AST/ASTConsumer.h>
#include <clang/Frontend/FrontendActions.h>
#include <clang/Rewrite/Core/Rewriter.h>

#include "rewrite_ast_visitor.h"

class RewriteASTConsumer : public clang::ASTConsumer {
public:
	RewriteASTConsumer(clang::Rewriter &R) : Visitor(R) {}

	// Override the method that gets called for each parsed top-level
	// declaration.
	bool HandleTopLevelDecl(clang::DeclGroupRef DR) override {
		for (auto &b : DR) {
			// Traverse the declaration using our AST visitor.
			Visitor.TraverseDecl(b);
			// b->dump();
		}
		return true;
	}

private:
	RewriteASTVisitor Visitor;
};

// For each source file provided to the tool, a new FrontendAction is created.
class InstrumentAction : public clang::ASTFrontendAction {
public:
	InstrumentAction() {};

	void EndSourceFileAction() override;
	clang::ASTConsumer *CreateASTConsumer(clang::CompilerInstance &, clang::StringRef) override;

private:
	clang::Rewriter TheRewriter;
	RewriteASTConsumer *InstrumentASTConsumer;
};