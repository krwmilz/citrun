//
// Tool used by tests.
//
#include "process_dir.h"

#include <cstring>
#include <err.h>
#include <iostream>
#include <unistd.h>		// getopt

static void
usage()
{
	std::cerr << "usage: citrun-dump [-ft] [-s srcfile]" << std::endl;
	exit(1);
}

static void
print_summary(ProcessDir const &pdir)
{
	for (auto &f : pdir.m_procfiles) {
		std::cout << "Found " << (f.is_alive() ? "alive" : "dead")
			<< " program with PID '" << f.m_pid << "'\n";
		std::cout << "  Runtime version: "
			<< unsigned(f.m_major) << "."
			<< unsigned(f.m_minor) << "\n";
		std::cout << "  Translation units: " << f.m_tus.size() << "\n";
		std::cout << "  Lines of code: " << f.m_program_loc << "\n";
		std::cout << "  Working directory: '" << f.m_cwd << "'\n";
	}

	exit(0);
}

int
main(int argc, char *argv[])
{
	ProcessDir pdir;
	int ch;
	int fflag = 0;
	char *sarg = NULL;
	int tflag = 0;

	pdir.scan();
	if (argc == 1)
		print_summary(pdir);

	if (pdir.m_procfiles.size() > 1)
		errx(1, "more than 1 process file found in directory!");

	ProcessFile f = pdir.m_procfiles[0];

	while ((ch = getopt(argc, argv, "fs:t")) != -1) {
		switch (ch) {
		case 'f':
			fflag = 1;
			break;
		case 't':
			tflag = 1;
			break;
		case 's':
			sarg = optarg;
			break;
		default:
			usage();
			break;
		}
	}
	argc -= optind;
	argv += optind;

	if (fflag) {
		for (auto &t : f.m_tus) {
			std::cout << t.comp_file_path << " "
				<< t.num_lines << std::endl;
		}
	}

	if (tflag) {
		for (int i = 0; i < 60; i++)
			std::cout << f.total_execs() << std::endl;
	}

	if (sarg) {
		const TranslationUnit *t;
		if ((t = f.find_tu(sarg)) == NULL)
			errx(1, "no source named '%s'\n", sarg);

		for (auto &l : t->source)
			std::cout << l << std::endl;
	}

	return 0;
}
