#include "inst_visitor.h"

#include <clang/AST/ASTConsumer.h>
#include <clang/Rewrite/Core/Rewriter.h>


class RewriteASTConsumer : public clang::ASTConsumer
{
	RewriteASTVisitor	 Visitor;

public:
	explicit		 RewriteASTConsumer(clang::Rewriter &R) :
					Visitor(R) {}

	// Override the method that gets called for each parsed top-level
	// declaration.
	virtual bool		 HandleTopLevelDecl(clang::DeclGroupRef DR) {
		for (auto &b : DR) {
			// Traverse the declaration using our AST visitor.
			Visitor.TraverseDecl(b);
			// b->dump();
		}
		return true;
	}

	RewriteASTVisitor	&get_visitor() { return Visitor; };
};
