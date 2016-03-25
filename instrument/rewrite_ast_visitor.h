#include <clang/AST/RecursiveASTVisitor.h>
#include <clang/Rewrite/Core/Rewriter.h>

using namespace clang;


class RewriteASTVisitor : public RecursiveASTVisitor<RewriteASTVisitor> {
public:
	RewriteASTVisitor(Rewriter &R) : TheRewriter(R), SM(R.getSourceMgr()) {}

	bool VisitVarDecl(VarDecl *d);
	bool VisitStmt(Stmt *s);
	bool VisitFunctionDecl(FunctionDecl *f);

private:
	Rewriter &TheRewriter;
	SourceManager &SM;
	LangOptions lopt;

	SourceLocation real_loc_end(Stmt *s);
};
