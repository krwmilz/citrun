#include <sstream>
#include <string>
#include <iostream>

#include <clang/AST/AST.h>
#include <clang/Lex/Lexer.h>

#include "instrumenter.h"

bool
instrumenter::VisitVarDecl(VarDecl *d)
{
	// std::cout << "HERE" << std::endl;
	return true;
}

bool
instrumenter::VisitStmt(Stmt *s)
{
	std::stringstream ss;
	unsigned line = SM.getPresumedLineNumber(s->getLocStart());
	Stmt *stmt_to_inst = NULL;

	if (isa<IfStmt>(s)) {
		IfStmt *IfStatement = cast<IfStmt>(s);
		stmt_to_inst = IfStatement->getCond();
	}
	else if (isa<ForStmt>(s)) {
		ForStmt *ForStatement = cast<ForStmt>(s);
		stmt_to_inst = ForStatement->getCond();
	}
	else if (isa<WhileStmt>(s)) {
		WhileStmt *WhileStatement = cast<WhileStmt>(s);
		stmt_to_inst = WhileStatement->getCond();
	}
	else if (isa<ReturnStmt>(s)) {
		ReturnStmt *ReturnStatement = cast<ReturnStmt>(s);
		stmt_to_inst = ReturnStatement->getRetValue();
	}
	/*
	else if (isa<BreakStmt>(s) || isa<ContinueStmt>(s) ||
		|| isa<SwitchStmt>(s) || isa<SwitchCase>(s)) {
	}
	*/
	else if (isa<DeclStmt>(s)) {
	}
	else if (isa<CallExpr>(s)) {
		stmt_to_inst = s;
	}

	if (stmt_to_inst == NULL)
		return true;

	ss << "(lines[" << line << "] = 1, ";
	TheRewriter.InsertTextBefore(stmt_to_inst->getLocStart(), ss.str());
	TheRewriter.InsertTextAfter(real_loc_end(stmt_to_inst), ")");

	return true;
}

bool
instrumenter::VisitFunctionDecl(FunctionDecl *f)
{
	// Only function definitions (with bodies), not declarations.
	if (f->hasBody()) {
		Stmt *FuncBody = f->getBody();
#if 0
		// Type name as string
		QualType QT = f->getReturnType();
		std::string TypeStr = QT.getAsString();

		// Function name
		DeclarationName DeclName = f->getNameInfo().getName();
		std::string FuncName = DeclName.getAsString();

		// Add comment before
		std::stringstream SSBefore;
		SSBefore << "// Begin function " << FuncName << " returning " << TypeStr
			<< "\n";
		SourceLocation ST = f->getSourceRange().getBegin();
		TheRewriter.InsertText(ST, SSBefore.str(), true, true);

		// And after
		std::stringstream SSAfter;
		SSAfter << "\n// End function " << FuncName;
		ST = FuncBody->getLocEnd().getLocWithOffset(1);
		TheRewriter.InsertText(ST, SSAfter.str(), true, true);
#endif
	}

	return true;
}

SourceLocation
instrumenter::real_loc_end(Stmt *d)
{
	SourceLocation _e(d->getLocEnd());
	return SourceLocation(Lexer::getLocForEndOfToken(_e, 0, SM, lopt));
}
