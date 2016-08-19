//
// Tool used by the end to end tests.
//
#include "shm.h"
#include "runtime_proc.h"

#include <cstring>
#include <iostream>
#include <unistd.h>		// getopt

static void
usage()
{
	std::cerr << "usage: citrun-dump [-f]" << std::endl;
	exit(1);
}

int
main(int argc, char *argv[])
{
	int ch;
	int fflag = 0;

	while ((ch = getopt(argc, argv, "f")) != -1) {
		switch (ch) {
		case 'f':
			fflag = 1;
			break;
		default:
			usage();
			break;
		}
	}
	argc -= optind;
	argv += optind;

	shm shm_conn;
	RuntimeProcess rt(shm_conn);

	if (fflag) {
		for (auto &t : rt.m_tus) {
			std::cout << t.comp_file_path << " "
				<< t.num_lines << std::endl;
		}

		return 0;
	}

	std::cout << "Version: "
			<< unsigned(rt.m_major) << "."
			<< unsigned(rt.m_minor) << "\n"
		<< "Program name: " << rt.m_progname << "\n"
		<< "Working directory: " << rt.m_cwd << "\n"
		<< "Translation units: " << rt.m_tus.size() << "\n"
		<< "Process ID: " << rt.m_pid << "\n"
		<< "Parent process ID: " << rt.m_ppid << "\n"
		<< "Process group ID: " << rt.m_pgrp << "\n";

	return 0;
}
