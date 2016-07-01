#include <sstream>
#include <string>

#include <clang/AST/AST.h>
#include <clang/Lex/Lexer.h>

#include "inst_ast_visitor.h"

bool
RewriteASTVisitor::VisitVarDecl(clang::VarDecl *d)
{
	return true;
}

bool
RewriteASTVisitor::VisitStmt(clang::Stmt *s)
{
	clang::Stmt *stmt_to_inst = NULL;

	if (clang::isa<clang::IfStmt>(s)) {
		stmt_to_inst = clang::cast<clang::IfStmt>(s)->getCond();
	}
	else if (clang::isa<clang::ForStmt>(s)) {
		stmt_to_inst = clang::cast<clang::ForStmt>(s)->getCond();
	}
	else if (clang::isa<clang::WhileStmt>(s)) {
		stmt_to_inst = clang::cast<clang::WhileStmt>(s)->getCond();
	}
	else if (clang::isa<clang::SwitchStmt>(s)) {
		stmt_to_inst = clang::cast<clang::SwitchStmt>(s)->getCond();
	}
	else if (clang::isa<clang::ReturnStmt>(s)) {
		stmt_to_inst = clang::cast<clang::ReturnStmt>(s)->getRetValue();
	}
	/*
	else if (isa<BreakStmt>(s) || isa<ContinueStmt>(s) ||
		|| isa<SwitchCase>(s)) {
	}
	*/
	else if (clang::isa<clang::DeclStmt>(s)) {
	}
	else if (clang::isa<clang::CallExpr>(s)) {
		stmt_to_inst = s;
	}

	if (stmt_to_inst == NULL)
		return true;

	std::stringstream ss;
	ss << "(++_citrun_lines["
		<< SM.getPresumedLineNumber(s->getLocStart())
		<< "], ";
	if (TheRewriter.InsertTextBefore(stmt_to_inst->getLocStart(), ss.str()))
		// writing failed, don't attempt to add ")"
		return true;

	TheRewriter.InsertTextAfter(real_loc_end(stmt_to_inst), ")");
	++rewrite_count;

	return true;
}

bool
RewriteASTVisitor::VisitFunctionDecl(clang::FunctionDecl *f)
{
	// Only function definitions (with bodies), not declarations.
	if (f->hasBody() == 0)
		return true;

	clang::Stmt *FuncBody = f->getBody();

	clang::DeclarationName DeclName = f->getNameInfo().getName();
	std::string FuncName = DeclName.getAsString();

	if (FuncName.compare("main") != 0)
		// Function is not main
		return true;

	std::string start_function("citrun_start();");

	clang::SourceLocation curly_brace(FuncBody->getLocStart().getLocWithOffset(1));
	TheRewriter.InsertTextBefore(curly_brace, start_function);

	return true;
}

clang::SourceLocation
RewriteASTVisitor::real_loc_end(clang::Stmt *d)
{
	clang::SourceLocation _e(d->getLocEnd());
	return clang::SourceLocation(clang::Lexer::getLocForEndOfToken(_e, 0, SM, lopt));
}
