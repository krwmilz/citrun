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
#include "inst_action.h"	// InstrumentActionFactory
#include "inst_fe.h"
#include "lib.h"		// citrun_major, citrun_minor
#include "prefix.h"		// prefix

#include <clang/Basic/Diagnostic.h>	// IgnoringDiagConsumer
#include <clang/Tooling/CommonOptionsParser.h>
#include <clang/Tooling/Tooling.h>
#include <llvm/Support/raw_os_ostream.h>

#include <algorithm>		// std::find_if
#include <cstdio>		// tmpnam
#include <cstring>		// strcmp
#include <iostream>		// std::cerr
#include <sstream>		// std::ostringstream


static llvm::cl::OptionCategory ToolingCategory("citrun_inst options");

InstFrontend::InstFrontend(int argc, char *argv[], bool is_citrun_inst) :
	m_start_time(std::chrono::high_resolution_clock::now()),
	m_args(argv, argv + argc),
	m_is_citruninst(is_citrun_inst),
	m_log(is_citrun_inst)
{
}

void
InstFrontend::log_identity()
{
	m_log << ">> citrun_inst v" << citrun_major << "." << citrun_minor;
	log_os_str();
	m_log << " called as " << m_args[0] << std::endl;
}

void
InstFrontend::get_paths()
{
	m_compilers_path = share_dir ;

	m_lib_path = lib_dir ;
	m_lib_path += dir_sep();
	m_lib_path += lib_name();

	m_log << "Compilers path = '" << m_compilers_path << "'" << std::endl;
}

//
// Tries to remove m_compilers_path from PATH otherwise it exits easily.
//
void
InstFrontend::clean_PATH()
{
	if (m_is_citruninst == true)
		return;

	char *path;
	if ((path = std::getenv("PATH")) == NULL) {
		std::cerr << "Error: PATH is not set." << std::endl;
		m_log <<     "Error: PATH is not set." << std::endl;
		exit(1);
	}

	m_log << "PATH = '" << path << "'" << std::endl;

	// Filter m_compilers_path out of PATH
	std::stringstream path_ss(path);
	std::string component;
	bool first_component = true;
	bool found_citrun_path = false;
	std::ostringstream new_path;

	while (std::getline(path_ss, component, path_sep())) {
		if (component == m_compilers_path) {
			found_citrun_path = true;
			continue;
		}

		if (first_component == false)
			new_path << path_sep();

		// It wasn't m_compilers_path, keep it
		new_path << component;
		first_component = false;
	}

	if (!found_citrun_path) {
		//
		// This is a really bad situation to be in. We are currently
		// executing and can't tell which PATH element we were called
		// from. If we exec there's a chance we'll get stuck in an
		// infinite exec loop.
		//
		// Error visibly so this can be fixed as soon as possible.
		//
		std::cerr << "Error: '" << m_compilers_path << "' not in PATH." << std::endl;
		m_log <<     "Error: '" << m_compilers_path << "' not in PATH." << std::endl;
		exit(1);
	}

	set_path(new_path.str());
}

//
// Guess if the argument is a sourcefile. If it is stash a backup of the file
// and sync the timestamps.
//
void
InstFrontend::save_if_srcfile(char *arg)
{
	std::array<std::string, 4> exts = {{ ".c", ".cc", ".cxx", ".cpp" }};
	if (std::find_if(exts.begin(), exts.end(), ends_with(arg)) == exts.end())
		return;

	char *dst_fn;
	if ((dst_fn = std::tmpnam(NULL)) == NULL) {
		m_log << "tmpnam failed." << std::endl;
		return;
	}

	m_source_files.push_back(arg);
	m_log << "Found source file '" << arg << "'" << std::endl;

	if (m_is_citruninst)
		// In this mode the modified source file is written to a
		// completely different file.
		return;

	copy_file(dst_fn, arg);
	m_temp_file_map[arg] = dst_fn;
}

//
// Walks the entire command line taking action on important arguments.
//
void
InstFrontend::process_cmdline()
{
	bool object_arg = false;
	bool compile_arg = false;

	//
	// Walk every argument one by one looking for preprocessor switches,
	// compile mode flags and source files.
	//
	for (auto &arg : m_args) {
		if (std::strcmp(arg, "-E") == 0 || std::strcmp(arg, "-MM") == 0) {
			// I don't know the repercussions of doing otherwise.
			m_log << "Preprocessor argument " << arg << " found"
				<< std::endl;
			exec_compiler();
		}
		else if (std::strcmp(arg, "-o") == 0)
			object_arg = true;
		else if (std::strcmp(arg, "-c") == 0)
			compile_arg = true;
#ifdef _WIN32
		else if (std::strcmp(arg, "/c") == 0)
			compile_arg = true;
#endif // _WIN32

		save_if_srcfile(arg);
	}

	if (is_link(object_arg, compile_arg)) {
		m_log << "Link detected, adding '"<< m_lib_path
			<< "' to command line." << std::endl;
		m_args.push_back(const_cast<char *>(m_lib_path.c_str()));
	}

	m_log << "Command line is '" << m_args[0];
	for (unsigned int i = 1; i < m_args.size(); ++i)
		m_log << " " << m_args[i];
	m_log << "'" << std::endl;

	if (m_source_files.size() != 0)
		return;

	m_log << "No source files found on command line." << std::endl;
	exec_compiler();
}

//
// Creates and executes InstrumentAction objects for detected source files.
//
void
InstFrontend::instrument()
{
	//
	// Create a special command line for ClangTool that looks like:
	// clang++ src1.c src2.c -- clang++ -I. -Isrc -c src1.c src2.c
	//
	std::vector<const char *> clang_argv;

	clang_argv.push_back(m_args[0]);
	for (auto &s : m_source_files)
		clang_argv.push_back(s.c_str());
	clang_argv.push_back("--");
	clang_argv.insert(clang_argv.end(), m_args.begin(), m_args.end());
#if defined(__OpenBSD__)
	clang_argv.push_back("-I/usr/local/lib/clang/3.8.0/include");
	m_log << "Added clangtool argument '" << clang_argv.back() << "'" << std::endl;
#elif defined(__APPLE__)
	clang_argv.push_back("-I/opt/local/libexec/llvm-3.8/lib/clang/3.8.1/include");
	m_log << "Added clangtool argument '" << clang_argv.back() << "'" << std::endl;
#elif defined(WIN32)
	clang_argv.push_back(R"(-IC:\Clang\lib\clang\3.9.1\include)");
	m_log << "Added clangtool argument '" << clang_argv.back() << "'" << std::endl;
#endif

	int clang_argc = clang_argv.size();
	clang::tooling::CommonOptionsParser
		op(clang_argc, &clang_argv[0], ToolingCategory);
	clang::tooling::ClangTool
		Tool(op.getCompilations(), op.getSourcePathList());

	//
	// Ignore all errors/warnings by default.
	// This makes Tool.run() always return 0 too.
	//
	Tool.setDiagnosticConsumer(new clang::IgnoringDiagConsumer());

	std::unique_ptr<InstrumentActionFactory> f =
		llvm::make_unique<InstrumentActionFactory>(m_log, m_is_citruninst, m_source_files);

	//
	// Run instrumentation. All source files are processed here.
	//
	Tool.run(f.get());

	// All of the time until now is the overhead citrun_inst adds.
	std::chrono::high_resolution_clock::time_point now =
		std::chrono::high_resolution_clock::now();
	m_log << std::chrono::duration_cast<std::chrono::milliseconds>(now - m_start_time).count()
		<< " Milliseconds spent rewriting source." << std::endl;

	// This is as far as we go in citrun_inst mode.
	if (m_is_citruninst)
		exit(0);
}

//
// Restore source files from stashed backups and sync timestamps.
//
void
InstFrontend::restore_original_src()
{
	for (auto &tmp_file : m_temp_file_map) {
		m_log << "Restored '" << tmp_file.first << "'" << std::endl;

		copy_file(tmp_file.first, tmp_file.second);
		unlink(tmp_file.second.c_str());
	}
}

void
InstFrontend::compile_instrumented()
{
	int ret;

	ret = fork_compiler();
	m_log << "Rewritten source compile " << (ret ? "failed" : "successful")
		<< std::endl;

	restore_original_src();

	if (ret)
		// Rewritten compile failed. Run again without modified src.
		exec_compiler();
}
