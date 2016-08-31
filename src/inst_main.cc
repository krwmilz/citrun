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
#include "inst_frontend.h"	// InstrumentFrontend
#include "version.h"		// citrun_major, citrun_minor

#include <sys/utsname.h>	// uname

#include <chrono>		// std::chrono::high_resolution_clock
#include <cstring>		// strcmp
#include <err.h>
#include <libgen.h>		// basename
#include <sstream>		// stringstream


void
clean_PATH(InstrumentLogger &llog)
{
	char *path;
	if ((path = std::getenv("PATH")) == NULL)
		errx(1, "Error: PATH is not set.");

	llog << "PATH='" << path << "'\n";

	// Filter CITRUN_SHARE out of PATH
	std::stringstream path_ss(path);
	std::ostringstream new_path;
	std::string component;
	bool first_component = 1;
	bool found_citrun_path = 0;

	while (std::getline(path_ss, component, ':')) {
		if (component.compare(CITRUN_SHARE) == 0) {
			found_citrun_path = 1;
			continue;
		}

		if (first_component == 0)
			new_path << ":";

		// It wasn't CITRUN_SHARE, keep it
		new_path << component;
		first_component = 0;
	}

	if (!found_citrun_path)
		errx(1, "Error: '%s' not in PATH.", CITRUN_SHARE);

	if (setenv("PATH", new_path.str().c_str(), 1))
		err(1, "setenv");
}

void
print_toolinfo(InstrumentLogger &llog)
{
	struct utsname utsname;

	llog << "citrun-inst "
		<< unsigned(citrun_major) << "."
		<< unsigned(citrun_minor) << " ";
	if (uname(&utsname) == -1)
		llog << "(Unknown OS) ";
	else {
		llog << "(" << utsname.sysname << "-"
			<< utsname.release << " "
			<< utsname.machine << ") ";
	}
	llog << "'" << CITRUN_SHARE << "'\n";
}

int
main(int argc, char *argv[])
{
	std::chrono::high_resolution_clock::time_point m_start_time =
		std::chrono::high_resolution_clock::now();

	char *base_name;
	if ((base_name = basename(argv[0])) == NULL)
		err(1, "basename");

	bool is_citruninst = false;
	if (std::strcmp(base_name, "citrun-inst") == 0)
		is_citruninst = true;

	InstrumentLogger llog(is_citruninst);
	print_toolinfo(llog);

	if (is_citruninst) {
		llog << ">> Welcome to C It Run! Have a nice day.\n";
	} else {
		// There's extra work to do if we're not running as citrun-inst.
		llog << "Tool called as '" << argv[0] << "'";
		if (std::strcmp(base_name, argv[0]) != 0) {
			llog << ", changing to '" << base_name << "'";
			argv[0] = base_name;
		}
		llog << ".\n";

		setprogname("citrun-inst");
		clean_PATH(llog);
	}

	InstrumentFrontend main(argc, argv, &llog, is_citruninst);
	main.process_cmdline();

	int ret = main.instrument();
	llog << "Rewriting " << (ret ? "failed.\n" : "successful.\n");

	std::chrono::high_resolution_clock::time_point now =
		std::chrono::high_resolution_clock::now();
	llog << std::chrono::duration_cast<std::chrono::milliseconds>(now - m_start_time).count()
		<< " Milliseconds spent rewriting source.\n";

	if (is_citruninst)
		return ret;
	if (ret) {
		// Rewriting failed. Original source files may be in an
		// inconsistent state.
		main.restore_original_src();
		main.exec_compiler();
	}

	ret = main.fork_compiler();
	llog << "Rewritten source compile "
		<< (ret ? "failed.\n" : "successful.\n");
	main.restore_original_src();

	if (ret)
		// Rewritten compile failed. Run again without modified src.
		main.exec_compiler();
	return 0;
}
