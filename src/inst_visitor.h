#include <array>
#include <clang/AST/RecursiveASTVisitor.h>
#include <clang/Rewrite/Core/Rewriter.h>

enum counters {
	FUNC_MAIN,
	FUNC_DEF,
	IF_STMT,
	FOR_STMT,
	WHILE_STMT,
	SWITCH_STMT,
	RET_STMT_VAL,
	CALL_EXPR,
	TOTAL_STMT,
	NCOUNTERS
};

class RewriteASTVisitor : public clang::RecursiveASTVisitor<RewriteASTVisitor> {
public:
	RewriteASTVisitor(clang::Rewriter &R) :
		m_counters(),
		m_counter_descr({
				"Functions called 'main'",
				"Function definitions",
				"If statements",
				"For statements",
				"While statements",
				"Switch statements",
				"Return statement values",
				"Call expressions",
				"Total statements"
				}),
		m_TheRewriter(R),
		m_SM(R.getSourceMgr())
	{}

	bool VisitVarDecl(clang::VarDecl *d);
	bool VisitStmt(clang::Stmt *s);
	bool VisitFunctionDecl(clang::FunctionDecl *f);

	std::array<int, NCOUNTERS> m_counters;
	std::array<std::string, NCOUNTERS> m_counter_descr;

private:
	bool			 modify_stmt(clang::Stmt *);
	clang::SourceLocation	 real_loc_end(clang::Stmt *);

	clang::Rewriter		&m_TheRewriter;
	clang::SourceManager	&m_SM;
	clang::LangOptions	 m_lopt;

};
