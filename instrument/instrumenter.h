#include <clang/AST/ASTConsumer.h>
#include <clang/AST/RecursiveASTVisitor.h>
#include <clang/Frontend/FrontendActions.h>
#include <clang/Rewrite/Core/Rewriter.h>

using namespace clang;


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

// For each source file provided to the tool, a new FrontendAction is created.
class MyFrontendAction : public ASTFrontendAction {
public:
	MyFrontendAction() {};

	void EndSourceFileAction() override;
	ASTConsumer *CreateASTConsumer(CompilerInstance &CI, StringRef file);

private:
	Rewriter TheRewriter;
};


#if 0
class MFAF : public FrontendActionFactory {
public:
	MFAF(std::vector<const char *> &i) : inst_files(i) {}

	FrontendAction *create() {
		return new MyFrontendAction();
	}

private:
	std::vector<const char *> inst_files;
};
#endif
