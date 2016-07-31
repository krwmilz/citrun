#include <clang/AST/RecursiveASTVisitor.h>
#include <clang/Rewrite/Core/Rewriter.h>

class RewriteASTVisitor : public clang::RecursiveASTVisitor<RewriteASTVisitor> {
public:
	RewriteASTVisitor(clang::Rewriter &R) :
		m_TheRewriter(R),
		m_SM(R.getSourceMgr()),
		m_rewrite_count(0) {}

	bool VisitVarDecl(clang::VarDecl *d);
	bool VisitStmt(clang::Stmt *s);
	bool VisitFunctionDecl(clang::FunctionDecl *f);
	unsigned int GetRewriteCount() { return m_rewrite_count; };
private:
	clang::Rewriter		&m_TheRewriter;
	clang::SourceManager	&m_SM;
	clang::LangOptions	 m_lopt;
	unsigned int		 m_rewrite_count;

	clang::SourceLocation	 real_loc_end(clang::Stmt *s);
};
