#include <err.h>	// err, errx
#include <fcntl.h>	// open
#include <stdlib.h>	// mktemp
#include <unistd.h>
#include <sys/stat.h>	// mode flags
#include <sys/wait.h>	// wait

#include <fstream>
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
	MyFrontendAction() {};

	void EndSourceFileAction() override {
		SourceManager &sm = TheRewriter.getSourceMgr();
		const FileID main_fid = sm.getMainFileID();
		// llvm::errs() << "** EndSourceFileAction for: "
		// 	<< sm.getFileEntryForID(main_fid)->getName()
		// 	<< "\n";

		SourceLocation start = sm.getLocForStartOfFile(main_fid);
		std::string file_name = getCurrentFile();

		std::stringstream ss;
		// Add declarations for coverage buffers
		int file_bytes = sm.getFileIDSize(main_fid);
		ss << "unsigned int lines[" << file_bytes << "];"
			<< std::endl;
		ss << "int size = " << file_bytes << ";" << std::endl;
		ss << "char file_name[] = \"" << file_name << "\";" << std::endl;
		TheRewriter.InsertTextAfter(start, ss.str());

		// rewrite the original source file
		int fd = open(file_name.c_str(), O_WRONLY | O_CREAT);
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
};

class MFAF : public FrontendActionFactory {
public:
	MFAF(std::vector<const char *> &i) : inst_files(i) {}

	FrontendAction *create() {
		return new MyFrontendAction();
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
instrument(int argc, char *argv[], std::vector<const char *> &source_files)
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
	// int ret = Tool.run(new MFAF(inst_files));
	int ret = Tool.run(newFrontendActionFactory<MyFrontendAction>());
	if (ret)
		errx(1, "Instrumentation failed");
}

int
main(int argc, char *argv[])
{
	std::vector<const char *> source_files;

	for (int i = 0; i < argc; i++) {
		int arg_len = strlen(argv[i]);
		if (arg_len < 4)
			continue;

		// compare last four bytes of argument
		if (strcmp(argv[i] + arg_len - 4, ".cpp") == 0 ||
		    strcmp(argv[i] + arg_len - 2, ".c") == 0)
			// keep track of original source file names
			source_files.push_back(argv[i]);
	}
	// very important that argv passed to execvp is NULL terminated
	argv[argc] = NULL;

	// run native command if there's no source files to instrument
	if (source_files.size() == 0) {
#if DEBUG
		warnx("no source files found on command line");
#endif
		clean_path();
		if (execvp(argv[0], argv))
			err(1, "execvp");
	}

	// backup original source files
	for (auto s : source_files) {
		std::ifstream src(s, std::ios::binary);
		std::string dst_fn(s);
		std::ofstream dst(dst_fn.append(".backup"), std::ios::binary);

		dst << src.rdbuf();

		src.close();
		dst.close();
	}

	// run instrumentation on detected source files
	instrument(argc, argv, source_files);

#if DEBUG
	std::cout << "Calling real compiler" << std::endl;
#endif
	clean_path();

	pid_t pid = fork();
	if (pid == 0) {
		// child, exec native compiler with instrumented source files
		if (execvp(argv[0], argv))
			err(1, "execvp");
	}
	else if (pid > 0) {
		// parent
		int status = 1;
		int ret;
		while (ret = wait(&status)) {
			if (ret != -1)
				break;
			if (errno == EINTR)
				continue;
			// something bad happened
			err(1, "wait");
		}
#ifdef DEBUG
		std::cout << "parent: restoring files" << std::endl;
#endif
		// restore original source files
		for (auto s : source_files) {
			std::ofstream dst(s, std::ios::binary);
			std::string src_fn(s);
			std::ifstream src(src_fn.append(".backup"), std::ios::binary);

			dst << src.rdbuf();

			src.close();
			dst.close();
		}
	}
	else
		err(1, "fork");
}
