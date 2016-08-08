#include <clang/AST/ASTConsumer.h>
#include <clang/Frontend/FrontendActions.h>
#include <clang/Rewrite/Core/Rewriter.h>
#include <clang/Tooling/Tooling.h>

#include "inst_ast_visitor.h"

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

	RewriteASTVisitor& get_visitor() { return Visitor; };
private:
	RewriteASTVisitor Visitor;
};

// For each source file provided to the tool, a new FrontendAction is created.
class InstrumentAction : public clang::ASTFrontendAction {
public:
	InstrumentAction(llvm::raw_fd_ostream *log, std::string const &pfx, bool citruninst) :
		m_log(log),
		m_pfx(pfx),
		m_is_citruninst(citruninst)
	{};

	void EndSourceFileAction() override;
	std::unique_ptr<clang::ASTConsumer> CreateASTConsumer(clang::CompilerInstance &, clang::StringRef) override;

private:
	clang::Rewriter		 m_TheRewriter;
	RewriteASTConsumer	*m_InstrumentASTConsumer;
	llvm::raw_fd_ostream	*m_log;
	std::string		 m_pfx;
	bool			 m_is_citruninst;
};
