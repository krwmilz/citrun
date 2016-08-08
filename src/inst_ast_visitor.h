#include <clang/AST/RecursiveASTVisitor.h>
#include <clang/Rewrite/Core/Rewriter.h>

class RewriteASTVisitor : public clang::RecursiveASTVisitor<RewriteASTVisitor> {
public:
	RewriteASTVisitor(clang::Rewriter &R) :
		m_counters(9, 0),
		m_TheRewriter(R),
		m_SM(R.getSourceMgr())
	{}

	bool VisitVarDecl(clang::VarDecl *d);
	bool VisitStmt(clang::Stmt *s);
	bool VisitFunctionDecl(clang::FunctionDecl *f);

	// Order defined by descriptions in inst_action.cc.
	std::vector<int>	 m_counters;

private:
	bool			 modify_stmt(clang::Stmt *);
	clang::SourceLocation	 real_loc_end(clang::Stmt *);

	clang::Rewriter		&m_TheRewriter;
	clang::SourceManager	&m_SM;
	clang::LangOptions	 m_lopt;

};
