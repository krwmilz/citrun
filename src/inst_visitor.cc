//
// Copyright (c) 2016 Kyle Milz <kyle@0x30.net>
//
// Permission to use, copy, modify, and distribute this software for any
// purpose with or without fee is hereby granted, provided that the above
// copyright notice and this permission notice appear in all copies.
//
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
// WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
// ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
// WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
// ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
// OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
//
#include "inst_visitor.h"

#include <clang/AST/AST.h>
#include <clang/Lex/Lexer.h>
#include <sstream>
#include <string>


bool
RewriteASTVisitor::TraverseStmt(clang::Stmt *s)
{
	if (s == NULL)
		return true;

	clang::SourceLocation start_loc = s->getLocStart();
	if (m_SM.isInMainFile(start_loc) == false)
		return false;

	// Instrumenting statement conditions in macros works perfectly.
	// Instrumenting binary operators in macros does not work well.
	if (clang::Lexer::isAtStartOfMacroExpansion(start_loc, m_SM, m_lopt))
		return false;

	RecursiveASTVisitor<RewriteASTVisitor>::TraverseStmt(s);
	return true;
}

bool
RewriteASTVisitor::TraverseDecl(clang::Decl *d)
{
	if (m_SM.isInMainFile(d->getLocStart()) == false)
		return false;

	if (clang::isa<clang::VarDecl>(d)) {
		clang::VarDecl *vd = clang::cast<clang::VarDecl>(d);
		if (vd->hasGlobalStorage())
			return false;
	}
	if (clang::isa<clang::RecordDecl>(d))
		return false;
	if (clang::isa<clang::EnumDecl>(d))
		return false;

	RecursiveASTVisitor<RewriteASTVisitor>::TraverseDecl(d);
	return true;
}

bool
RewriteASTVisitor::VisitVarDecl(clang::VarDecl *d)
{
	return true;
}

bool
RewriteASTVisitor::VisitStmt(clang::Stmt *s)
{
	++m_counters[TOTAL_STMT];
	return true;
}

bool
RewriteASTVisitor::VisitIfStmt(clang::IfStmt *i)
{
	modify_stmt(i->getCond(), m_counters[IF_STMT]);
	return true;
}

bool
RewriteASTVisitor::VisitForStmt(clang::ForStmt *f)
{
	modify_stmt(f->getCond(), m_counters[FOR_STMT]);
	return true;
}

bool
RewriteASTVisitor::VisitWhileStmt(clang::WhileStmt *w)
{
	modify_stmt(w->getCond(), m_counters[WHILE_STMT]);
	return true;
}

bool
RewriteASTVisitor::VisitDoStmt(clang::DoStmt *d)
{
	modify_stmt(d->getCond(), m_counters[DOWHILE_STMT]);
	return true;
}

bool
RewriteASTVisitor::VisitSwitchStmt(clang::SwitchStmt *s)
{
	modify_stmt(s->getCond(), m_counters[SWITCH_STMT]);
	return true;
}

bool
RewriteASTVisitor::VisitReturnStmt(clang::ReturnStmt *r)
{
	modify_stmt(r->getRetValue(), m_counters[RET_STMT_VAL]);
	return true;
}

bool
RewriteASTVisitor::VisitCallExpr(clang::CallExpr *c)
{
	modify_stmt(c, m_counters[CALL_EXPR]);
	return true;
}

bool
RewriteASTVisitor::VisitBinaryOperator(clang::BinaryOperator *b)
{

	// If we can't rewrite the last token, don't even start.
	if (b->getLocEnd().isMacroID())
		return true;
	modify_stmt(b, m_counters[BIN_OPER]);
	return true;
}

bool
RewriteASTVisitor::modify_stmt(clang::Stmt *s, int &counter)
{
	if (s == NULL)
		return false;

	// If x = y is the original statement on line 19 then we try rewriting
	// as (++_citrun[19], x = y).
	std::stringstream ss;
	ss << "(++_citrun["
		<< m_SM.getPresumedLineNumber(s->getLocStart()) - 1
		<< "], ";

	if (m_TheRewriter.InsertTextBefore(s->getLocStart(), ss.str())) {
		// writing failed, don't attempt to add ")"
		++m_counters[REWRITE_ERROR];
		return false;
	}
	m_TheRewriter.InsertTextAfter(real_loc_end(s), ")");

	++counter;
	return true;
}

bool
RewriteASTVisitor::VisitFunctionDecl(clang::FunctionDecl *f)
{
	// Only function definitions (with bodies), not declarations.
	if (f->hasBody() == 0)
		return true;

	std::stringstream rewrite_text;

	// main() is a special case because it must start the runtime thread.
	clang::DeclarationName DeclName = f->getNameInfo().getName();
	if (DeclName.getAsString() == "main") {
		++m_counters[FUNC_MAIN];
		rewrite_text << "citrun_start();";
	}

	clang::Stmt *FuncBody = f->getBody();
	clang::SourceLocation curly_brace(FuncBody->getLocStart().getLocWithOffset(1));

	// Animate function calls by firing the entire declaration.
	int decl_start = m_SM.getPresumedLineNumber(f->getLocStart());
	int decl_end = m_SM.getPresumedLineNumber(curly_brace);
	for (int i = decl_start; i <= decl_end; ++i)
		rewrite_text << "++_citrun[" << i - 1 << "];";

	// Rewrite the function source right after the beginning curly brace.
	m_TheRewriter.InsertTextBefore(curly_brace, rewrite_text.str());

	++m_counters[FUNC_DEF];
	return true;
}

clang::SourceLocation
RewriteASTVisitor::real_loc_end(clang::Stmt *d)
{
	clang::SourceLocation _e(d->getLocEnd());
	return clang::Lexer::getLocForEndOfToken(_e, 0, m_SM, m_lopt);
}
