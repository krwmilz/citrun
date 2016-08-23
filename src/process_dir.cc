#include "process_dir.h"

#include <sys/types.h>

#include <err.h>
#include <cstdlib>		// getenv
#include <cstring>
#include <iostream>
#include <dirent.h>		// opendir, readdir

ProcessDir::ProcessDir()
{
	const char *process_dir;
	if (std::getenv("CITRUN_TESTING") != NULL)
		process_dir = "runtime/";
	else
		process_dir = "/tmp/citrun/";

	DIR *dirp;
	if ((dirp = opendir(process_dir)) == NULL)
		err(1, "opendir");

	struct dirent *dp;
	while ((dp = readdir(dirp)) != NULL) {

		if (std::strcmp(dp->d_name, ".") == 0 ||
		    std::strcmp(dp->d_name, "..") == 0)
			continue;

		std::string p(process_dir);
		p.append(dp->d_name);

		m_procfiles.push_back(ProcessFile(p));
	}
}
