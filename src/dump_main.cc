//
// Tool used by tests.
//
#include "shm.h"
#include "runtime_proc.h"

#include <sys/mman.h>		// shm_unlink

#include <cstring>
#include <err.h>
#include <iostream>
#include <unistd.h>		// getopt

static void
usage()
{
	std::cerr << "usage: citrun-dump [-ft] [-s srcfile] [-u shm path]" << std::endl;
	exit(1);
}

static void
count_execs(RuntimeProcess &rt)
{
	uint64_t total = 0;

	for (auto &t : rt.m_tus)
		for (int i = 0; i < t.num_lines; ++i)
			total += t.exec_diffs[i];

	std::cout << total << std::endl;
}

int
main(int argc, char *argv[])
{
	int ch;
	int orig_argc = argc;
	int fflag = 0;
	char *sarg = NULL;
	int tflag = 0;

	while ((ch = getopt(argc, argv, "fs:tu:")) != -1) {
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
		case 'u':
			shm_unlink(optarg);
			return 0;
		default:
			usage();
			break;
		}
	}
	argc -= optind;
	argv += optind;

	shm shm_conn;
	RuntimeProcess rt(shm_conn);

	if (orig_argc == 1) {
		std::cout << "Version:           "
			<< unsigned(rt.m_major) << "."
			<< unsigned(rt.m_minor) << "\n"
			<< "Program name:      " << rt.m_progname << "\n"
			<< "Translation units: " << rt.m_tus.size() << "\n";
	}

	if (fflag) {
		for (auto &t : rt.m_tus) {
			std::cout << t.comp_file_path << " "
				<< t.num_lines << std::endl;
		}
	}

	if (0) {
		std::cout << "Working directory:\t" << rt.m_cwd << "\n"
		<< "Process ID:\t" << rt.m_pid << "\n"
		<< "Parent process ID:\t" << rt.m_ppid << "\n"
		<< "Process group ID:\t" << rt.m_pgrp << "\n";
	}

	if (tflag) {
		for (int i = 0; i < 60; i++)
			count_execs(rt);
	}

	if (sarg) {
		const TranslationUnit *t;
		if ((t = rt.find_tu(sarg)) == NULL)
			errx(1, "no source named '%s'\n", sarg);

		for (auto &l : t->source)
			std::cout << l << std::endl;
	}

	return 0;
}
