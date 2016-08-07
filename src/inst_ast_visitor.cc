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
		<< m_SM.getPresumedLineNumber(s->getLocStart())
		<< "], ";
	if (m_TheRewriter.InsertTextBefore(stmt_to_inst->getLocStart(), ss.str()))
		// writing failed, don't attempt to add ")"
		return true;

	m_TheRewriter.InsertTextAfter(real_loc_end(stmt_to_inst), ")");
	++m_rewrite_count;

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
	if (DeclName.getAsString() == "main")
		rewrite_text << "citrun_start();";

	clang::Stmt *FuncBody = f->getBody();
	clang::SourceLocation curly_brace(FuncBody->getLocStart().getLocWithOffset(1));

	// Animate function calls by firing the entire declaration.
	int decl_start = m_SM.getPresumedLineNumber(f->getLocStart());
	int decl_end = m_SM.getPresumedLineNumber(curly_brace);
	for (int i = decl_start; i <= decl_end; i++)
		rewrite_text << "++_citrun_lines[" << i << "];";

	// Rewrite the function source right after the beginning curly brace.
	m_TheRewriter.InsertTextBefore(curly_brace, rewrite_text.str());

	return true;
}

clang::SourceLocation
RewriteASTVisitor::real_loc_end(clang::Stmt *d)
{
	clang::SourceLocation _e(d->getLocEnd());
	return clang::SourceLocation(clang::Lexer::getLocForEndOfToken(_e, 0, m_SM, m_lopt));
}
