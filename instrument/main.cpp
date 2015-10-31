#include <err.h>	// err, errx
#include <fcntl.h>	// open
#include <stdlib.h>	// mktemp
#include <unistd.h>
#include <sys/stat.h>	// mode flags

#include <iostream>
#include <sstream>
#include <string>

#include <clang/Frontend/FrontendActions.h>
#include <clang/Frontend/CompilerInstance.h>
#include <clang/Tooling/CommonOptionsParser.h>
#include <clang/Tooling/Tooling.h>
#include <clang/Rewrite/Core/Rewriter.h>
#include <llvm/Support/raw_ostream.h>

#include "instrumenter.h"

using namespace clang;
using namespace clang::driver;
using namespace clang::tooling;

static llvm::cl::OptionCategory ToolingCategory("instrument options");

// For each source file provided to the tool, a new FrontendAction is created.
class MyFrontendAction : public ASTFrontendAction {
public:
	MyFrontendAction(std::vector<const char *> &);
	void EndSourceFileAction() override {
		SourceManager &sm = TheRewriter.getSourceMgr();
		const FileID main_fid = sm.getMainFileID();
		// llvm::errs() << "** EndSourceFileAction for: "
		// 	<< sm.getFileEntryForID(main_fid)->getName()
		// 	<< "\n";

		SourceLocation start = sm.getLocForStartOfFile(main_fid);

		std::stringstream ss;
		// Add declarations for coverage buffers
		int file_bytes = sm.getFileIDSize(main_fid);
		ss << "unsigned int lines[" << file_bytes << "];"
			<< std::endl;
		ss << "int size = " << file_bytes << ";" << std::endl;
		TheRewriter.InsertTextAfter(start, ss.str());

		// Now emit the rewritten buffer.
		int fd = open(inst_files[0], O_WRONLY | O_CREAT,
				S_IRUSR | S_IWUSR);
		if (fd < 0)
			err(1, "open");
		llvm::raw_fd_ostream output(fd, /* close */ 1);
		TheRewriter.getEditBuffer(main_fid).write(output);
		// TheRewriter.getEditBuffer(main_fid).write(llvm::outs());
	}

	ASTConsumer *CreateASTConsumer(CompilerInstance &CI,
			StringRef file) override {
		// llvm::errs() << "** Creating AST consumer for: " << file << "\n";
		SourceManager &sm = CI.getSourceManager();
		TheRewriter.setSourceMgr(sm, CI.getLangOpts());

		return new MyASTConsumer(TheRewriter);
	}

private:
	Rewriter TheRewriter;

	std::vector<const char *> inst_files;
};

MyFrontendAction::MyFrontendAction(std::vector<const char *> &i) :
	inst_files(i)
{
}

class MFAF : public FrontendActionFactory {
public:
	MFAF(std::vector<const char *> &i) : inst_files(i) {}

	FrontendAction *create() {
		return new MyFrontendAction(inst_files);
	}

private:
	std::vector<const char *> inst_files;
};

void
clean_path()
{
	// remove SCV_PATH from PATH

	char *scv_path = getenv("SCV_PATH");
	char *path = getenv("PATH");
	if (scv_path == NULL)
		errx(1, "SCV_PATH not found in environment, not running "
			"native compiler");
	else if (path == NULL)
		errx(1, "PATH not set, your build system needs to use "
			"the PATH for this tool to be useful.");
#ifdef DEBUG
	std::cout << "SCV_PATH=" << scv_path << std::endl;
	std::cout << "old PATH=" << path << std::endl;
#endif

	int new_path_pos = 0;
	char *new_path = (char *)calloc(strlen(path), 1);

	char *tok = strtok(path, ":");
	bool wrote_first_token = false;
	while (tok != NULL) {
		if (strncmp(scv_path, tok, 1024) != 0) {
			// didn't find SCV_PATH in PATH
			if (wrote_first_token == true) {
				strcat(new_path + new_path_pos, ":");
				new_path_pos++;
			}
			strcat(new_path + new_path_pos, tok);
			new_path_pos += strlen(tok);
			wrote_first_token = true;
		}
		tok = strtok(NULL, ":");
	}

	setenv("PATH", new_path, 1);
#ifdef DEBUG
	std::cout << "new " << new_path << std::endl;
	system("env");
#endif
}

void
instrument(int argc, char *argv[], std::vector<const char *> &source_files,
		std::vector<const char *> &inst_files)
{
	const char *clang_argv[source_files.size() + 1 + argc];
	int clang_argc = 0;

	clang_argv[clang_argc++] = argv[0];
	for (auto s : source_files)
		clang_argv[clang_argc++] = s;

	clang_argv[clang_argc++] = "--";

	// append original command line verbatim after --
	for (int i = 0; i < argc; i++)
		clang_argv[clang_argc++] = argv[i];

#ifdef DEBUG
	// print out
	for (int i = 0; i < clang_argc; i++)
		std::cout << clang_argv[i] << " ";
	std::cout << std::endl;
#endif

	// give clang it's <source files> -- <native command line> arg style
	CommonOptionsParser op(clang_argc, clang_argv, ToolingCategory);
	ClangTool Tool(op.getCompilations(), op.getSourcePathList());

	// ClangTool::run accepts a FrontendActionFactory, which is then used to
	// create new objects implementing the FrontendAction interface. Here we
	// use the helper newFrontendActionFactory to create a default factory
	// that will return a new MyFrontendAction object every time.  To
	// further customize this, we could create our own factory class.
	int ret = Tool.run(new MFAF(inst_files));
	// int ret = Tool.run(newFrontendActionFactory<MyFrontendAction>());
	if (ret)
		errx(1, "Instrumentation failed");
}

int
main(int argc, char *argv[])
{
	std::vector<const char *> source_files;
	std::vector<const char *> inst_files;
	char *exec_argv[argc + 1];

	for (int i = 0; i < argc; i++) {
		exec_argv[i] = strdup(argv[i]);

		int arg_len = strlen(argv[i]);
		if (arg_len < 4)
			continue;

		// compare last four bytes of argument
		if (strcmp(argv[i] + arg_len - 4, ".cpp") == 0 ||
		    strcmp(argv[i] + arg_len - 2, ".c") == 0) {
			// keep track of original source file names
			source_files.push_back(argv[i]);

			char *inst_filename = (char *)calloc(PATH_MAX, 1);
			if (inst_filename == NULL)
				err(1, "calloc");

			strncpy(inst_filename, argv[i], arg_len - 2);
			strcat(inst_filename, "_inst.c");

			// source code rewriter needs to know this file
			inst_files.push_back(inst_filename);
			// native compiler uses this source file instead
			exec_argv[i] = inst_filename;
		}
	}
	// very important that argv passed to execvp is NULL terminated
	exec_argv[argc] = NULL;

	// run native command if there's no source files to instrument
	if (source_files.size() == 0) {
		warnx("no source files found on command line");

		clean_path();
		if (execvp(exec_argv[0], exec_argv))
			err(1, "execvp");
	}

	// run instrumentation on detected source files
	instrument(argc, argv, source_files, inst_files);

#if DEBUG
	std::cout << "Calling real compiler " << exec_argv[0] << std::endl;
#endif

	// exec native compiler with instrumented source files
	clean_path();
	if (execvp(exec_argv[0], exec_argv))
		err(1, "execvp");
}
