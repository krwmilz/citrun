#include <sstream>
#include <string>

#include <clang/AST/AST.h>
#include <clang/Lex/Lexer.h>

#include "rewrite_ast_visitor.h"

bool
RewriteASTVisitor::VisitVarDecl(VarDecl *d)
{
	return true;
}

bool
RewriteASTVisitor::VisitStmt(Stmt *s)
{
	std::stringstream ss;
	unsigned line = SM.getPresumedLineNumber(s->getLocStart());
	Stmt *stmt_to_inst = NULL;

	if (isa<IfStmt>(s)) {
		stmt_to_inst = cast<IfStmt>(s)->getCond();
	}
	else if (isa<ForStmt>(s)) {
		stmt_to_inst = cast<ForStmt>(s)->getCond();
	}
	else if (isa<WhileStmt>(s)) {
		stmt_to_inst = cast<WhileStmt>(s)->getCond();
	}
	else if (isa<SwitchStmt>(s)) {
		stmt_to_inst = cast<SwitchStmt>(s)->getCond();
	}
	else if (isa<ReturnStmt>(s)) {
		stmt_to_inst = cast<ReturnStmt>(s)->getRetValue();
	}
	/*
	else if (isa<BreakStmt>(s) || isa<ContinueStmt>(s) ||
		|| isa<SwitchCase>(s)) {
	}
	*/
	else if (isa<DeclStmt>(s)) {
	}
	else if (isa<CallExpr>(s)) {
		stmt_to_inst = s;
	}

	if (stmt_to_inst == NULL)
		return true;

	ss << "(++_scv_lines[" << line << "], ";
	if (TheRewriter.InsertTextBefore(stmt_to_inst->getLocStart(), ss.str()))
		// writing failed, don't attempt to add ")"
		return true;

	TheRewriter.InsertTextAfter(real_loc_end(stmt_to_inst), ")");

	return true;
}

bool
RewriteASTVisitor::VisitFunctionDecl(FunctionDecl *f)
{
	// Only function definitions (with bodies), not declarations.
	if (f->hasBody() == 0)
		return true;

	Stmt *FuncBody = f->getBody();

	DeclarationName DeclName = f->getNameInfo().getName();
	std::string FuncName = DeclName.getAsString();

	if (FuncName.compare("main") != 0)
		// Function is not main
		return true;

	std::stringstream ss;
	// On some platforms we need to depend directly on a symbol provided by
	// the runtime. Normally this isn't needed because the runtime only
	// depends on symbols in the isntrumented application.
	ss << "libscv_init();";
	SourceLocation curly_brace(FuncBody->getLocStart().getLocWithOffset(1));
	TheRewriter.InsertTextBefore(curly_brace, ss.str());

	return true;
}

SourceLocation
RewriteASTVisitor::real_loc_end(Stmt *d)
{
	SourceLocation _e(d->getLocEnd());
	return SourceLocation(Lexer::getLocForEndOfToken(_e, 0, SM, lopt));
}
