#include "process_dir.h"

#include <sys/types.h>

#include <err.h>
#include <cstring>
#include <iostream>
#include <dirent.h>		// opendir, readdir

ProcessDir::ProcessDir()
{
	DIR *dirp;
	if ((dirp = opendir("/tmp/citrun")) == NULL)
		err(1, "opendir");

	struct dirent *dp;
	while ((dp = readdir(dirp)) != NULL) {

		if (std::strcmp(dp->d_name, ".") == 0 ||
		    std::strcmp(dp->d_name, "..") == 0)
			continue;

		std::string p("/tmp/citrun/");
		p.append(dp->d_name);

		m_procfiles.push_back(ProcessFile(p));
	}
}
