#include "process_dir.h"

#include <err.h>
#include <cstdlib>		// getenv
#include <cstring>
#include <iostream>

ProcessDir::ProcessDir()
{
	if (std::getenv("CITRUN_TOOLS") != NULL)
		m_procdir = "runtime/";
	else
		m_procdir = "/tmp/citrun/";

	if ((m_dirp = opendir(m_procdir)) == NULL)
		err(1, "opendir");
}

std::vector<std::string> *
ProcessDir::scan()
{
	std::vector<std::string>	*new_files;
	struct dirent			*dp;

	new_files = new std::vector<std::string>();

	rewinddir(m_dirp);
	while ((dp = readdir(m_dirp)) != NULL) {

		if (std::strcmp(dp->d_name, ".") == 0 ||
		    std::strcmp(dp->d_name, "..") == 0)
			continue;

		std::string p(m_procdir);
		p.append(dp->d_name);

		if (m_known_files.find(p) != m_known_files.end())
			// We already know this file.
			continue;

		m_known_files.insert(p);
		new_files->push_back(p);
	}

	return new_files;
}
