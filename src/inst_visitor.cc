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
#include <clang/AST/AST.h>
#include <clang/Lex/Lexer.h>
#include <sstream>
#include <string>

#include "inst_visitor.h"

bool
RewriteASTVisitor::TraverseStmt(clang::Stmt *s)
{
	if (s == NULL)
		return true;

	clang::SourceLocation start_loc = s->getLocStart();
	clang::FullSourceLoc full_loc(start_loc, m_SM);

	if (full_loc.isInSystemHeader())
		return false;

	RecursiveASTVisitor<RewriteASTVisitor>::TraverseStmt(s);
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
	m_counters[TOTAL_STMT]++;

	if (clang::isa<clang::IfStmt>(s)) {
		s = clang::cast<clang::IfStmt>(s)->getCond();
		modify_stmt(s, m_counters[IF_STMT]);
	}
	else if (clang::isa<clang::ForStmt>(s)) {
		s = clang::cast<clang::ForStmt>(s)->getCond();
		modify_stmt(s, m_counters[FOR_STMT]);
	}
	else if (clang::isa<clang::WhileStmt>(s)) {
		s = clang::cast<clang::WhileStmt>(s)->getCond();
		modify_stmt(s, m_counters[WHILE_STMT]);
	}
	else if (clang::isa<clang::DoStmt>(s)) {
		s = clang::cast<clang::DoStmt>(s)->getCond();
		modify_stmt(s, m_counters[DOWHILE_STMT]);
	}
	else if (clang::isa<clang::SwitchStmt>(s)) {
		s = clang::cast<clang::SwitchStmt>(s)->getCond();
		modify_stmt(s, m_counters[SWITCH_STMT]);
	}
	else if (clang::isa<clang::ReturnStmt>(s)) {
		s = clang::cast<clang::ReturnStmt>(s)->getRetValue();
		modify_stmt(s, m_counters[RET_STMT_VAL]);
	}
	/*
	else if (isa<BreakStmt>(s) || isa<ContinueStmt>(s) ||
		|| isa<SwitchCase>(s)) {
	}
	else if (clang::isa<clang::DeclStmt>(s)) {
	}
	*/
	else if (clang::isa<clang::CallExpr>(s)) {
		modify_stmt(s, m_counters[CALL_EXPR]);
	}

	return true;
}

bool
RewriteASTVisitor::modify_stmt(clang::Stmt *s, int &counter)
{
	if (s == NULL)
		return false;

	// If x = y is the original statement on line 19 then we try rewriting
	// as (++citrun_lines[19], x = y).
	std::stringstream ss;
	ss << "(++_citrun_lines["
		<< m_SM.getPresumedLineNumber(s->getLocStart()) - 1
		<< "], ";

	if (m_TheRewriter.InsertTextBefore(s->getLocStart(), ss.str())) {
		// writing failed, don't attempt to add ")"
		m_counters[REWRITE_ERROR]++;
		return false;
	}
	m_TheRewriter.InsertTextAfter(real_loc_end(s), ")");

	counter++;
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
		m_counters[FUNC_MAIN]++;
		rewrite_text << "citrun_start();";
	}

	clang::Stmt *FuncBody = f->getBody();
	clang::SourceLocation curly_brace(FuncBody->getLocStart().getLocWithOffset(1));

	// Animate function calls by firing the entire declaration.
	int decl_start = m_SM.getPresumedLineNumber(f->getLocStart());
	int decl_end = m_SM.getPresumedLineNumber(curly_brace);
	for (int i = decl_start; i <= decl_end; i++)
		rewrite_text << "++_citrun_lines[" << i - 1 << "];";

	// Rewrite the function source right after the beginning curly brace.
	m_TheRewriter.InsertTextBefore(curly_brace, rewrite_text.str());

	m_counters[FUNC_DEF]++;
	return true;
}

clang::SourceLocation
RewriteASTVisitor::real_loc_end(clang::Stmt *d)
{
	clang::SourceLocation _e(d->getLocEnd());
	return clang::SourceLocation(clang::Lexer::getLocForEndOfToken(_e, 0, m_SM, m_lopt));
}
