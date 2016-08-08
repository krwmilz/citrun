#include <clang/AST/RecursiveASTVisitor.h>
#include <clang/Rewrite/Core/Rewriter.h>

class RewriteASTVisitor : public clang::RecursiveASTVisitor<RewriteASTVisitor> {
public:
	RewriteASTVisitor(clang::Rewriter &R) :
		m_totalstmt(0),
		m_funcdecl(0),
		m_ifstmt(0),
		m_forstmt(0),
		m_whilestmt(0),
		m_switchstmt(0),
		m_returnstmt(0),
		m_callexpr(0),
		m_mainfunc(0),
		m_TheRewriter(R),
		m_SM(R.getSourceMgr())
		{}

	bool VisitVarDecl(clang::VarDecl *d);
	bool VisitStmt(clang::Stmt *s);
	bool VisitFunctionDecl(clang::FunctionDecl *f);

	unsigned int		 m_totalstmt;
	unsigned int		 m_funcdecl;
	unsigned int		 m_ifstmt;
	unsigned int		 m_forstmt;
	unsigned int		 m_whilestmt;
	unsigned int		 m_switchstmt;
	unsigned int		 m_returnstmt;
	unsigned int		 m_callexpr;
	unsigned int		 m_mainfunc;

private:
	bool			 modify_stmt(clang::Stmt *);
	clang::SourceLocation	 real_loc_end(clang::Stmt *);

	clang::Rewriter		&m_TheRewriter;
	clang::SourceManager	&m_SM;
	clang::LangOptions	 m_lopt;

};
