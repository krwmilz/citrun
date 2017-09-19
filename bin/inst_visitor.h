#include <array>
#include <clang/AST/RecursiveASTVisitor.h>
#include <clang/Rewrite/Core/Rewriter.h>

enum counters {
	FUNC_DEF,
	IF_STMT,
	FOR_STMT,
	WHILE_STMT,
	DOWHILE_STMT,
	SWITCH_STMT,
	RET_STMT_VAL,
	CALL_EXPR,
	TOTAL_STMT,
	BIN_OPER,
	REWRITE_ERROR,
	NCOUNTERS
};

class RewriteASTVisitor : public clang::RecursiveASTVisitor<RewriteASTVisitor>
{
	bool			 modify_stmt(clang::Stmt *, int &);
	clang::SourceLocation	 real_loc_end(clang::Stmt *);

	clang::Rewriter		&m_TheRewriter;
	clang::SourceManager	&m_SM;
	clang::LangOptions	 m_lopt;

public:
	explicit		 RewriteASTVisitor(clang::Rewriter &R);
	virtual			~RewriteASTVisitor() {};

	virtual bool		 TraverseStmt(clang::Stmt *);
	virtual bool		 TraverseDecl(clang::Decl *);

	bool			 VisitVarDecl(clang::VarDecl *d);
	bool			 VisitStmt(clang::Stmt *s);
	bool			 VisitFunctionDecl(clang::FunctionDecl *f);

	bool			 VisitIfStmt(clang::IfStmt *);
	bool			 VisitForStmt(clang::ForStmt *);
	bool			 VisitWhileStmt(clang::WhileStmt *);
	bool			 VisitDoStmt(clang::DoStmt *);
	bool			 VisitSwitchStmt(clang::SwitchStmt *);
	bool			 VisitReturnStmt(clang::ReturnStmt *);
	bool			 VisitCallExpr(clang::CallExpr *);
	bool			 VisitBinaryOperator(clang::BinaryOperator *);

	std::array<int, NCOUNTERS> m_counters;
	std::array<std::string, NCOUNTERS> m_counter_descr;
};
