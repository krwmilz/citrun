#include <clang/AST/RecursiveASTVisitor.h>
#include <clang/Rewrite/Core/Rewriter.h>


class RewriteASTVisitor : public clang::RecursiveASTVisitor<RewriteASTVisitor> {
public:
	RewriteASTVisitor(clang::Rewriter &R) : TheRewriter(R), SM(R.getSourceMgr()) {}

	bool VisitVarDecl(clang::VarDecl *d);
	bool VisitStmt(clang::Stmt *s);
	bool VisitFunctionDecl(clang::FunctionDecl *f);

private:
	clang::Rewriter &TheRewriter;
	clang::SourceManager &SM;
	clang::LangOptions lopt;

	clang::SourceLocation real_loc_end(clang::Stmt *s);
};
