#include "inst_consumer.h"
#include "inst_log.h"

#include <clang/Frontend/FrontendActions.h>
#include <clang/Rewrite/Core/Rewriter.h>
#include <clang/Tooling/Tooling.h>


// For each source file provided to the tool, a new FrontendAction is created.
class InstrumentAction : public clang::ASTFrontendAction
{
	void			 write_modified_src(clang::FileID const &);

	clang::Rewriter		 m_TheRewriter;
	RewriteASTConsumer	*m_InstrumentASTConsumer;
	InstrumentLogger&	 m_log;
	bool			 m_is_citruninst;
	std::string		 m_compiler_file_name;

public:
	InstrumentAction(InstrumentLogger &log, bool citruninst,
			std::string const &filename) :
		m_log(log),
		m_is_citruninst(citruninst),
		m_compiler_file_name(filename)
	{};

	void EndSourceFileAction() override;
	std::unique_ptr<clang::ASTConsumer> CreateASTConsumer(clang::CompilerInstance &, clang::StringRef) override;
};

//
// Needed because we pass custom stuff down into the ASTFrontendAction
//
class InstrumentActionFactory : public clang::tooling::FrontendActionFactory
{
	InstrumentLogger&	 m_log;
	bool			 m_is_citruninst;
	std::vector<std::string> m_source_files;
	int			 m_i;

public:
	InstrumentActionFactory(InstrumentLogger &log, bool citruninst, std::vector<std::string> const &src_files) :
		m_log(log),
		m_is_citruninst(citruninst),
		m_source_files(src_files),
		m_i(0)
	{};

	clang::ASTFrontendAction *create() {
		return new InstrumentAction(m_log, m_is_citruninst, m_source_files[m_i++]);
	}
};
