#include "process_dir.h"

#include <err.h>
#include <cstdlib>		// getenv
#include <cstring>
#include <iostream>

#include <sys/stat.h>


citrun::process_dir::process_dir()
{
	if ((m_procdir = std::getenv("CITRUN_PROCDIR")) == NULL)
		m_procdir = "/tmp/citrun/";

	if ((m_dirp = opendir(m_procdir)) == NULL) {
		if (errno != ENOENT)
			err(1, "opendir '%s'", m_procdir);

		// Create if there was no such file or directory.
		mkdir(m_procdir, S_IRWXU);
		if ((m_dirp = opendir(m_procdir)) == NULL)
			err(1, "opendir '%s'", m_procdir);
	}
}

std::vector<std::string>
citrun::process_dir::scan()
{
	std::vector<std::string>	 new_files;
	struct dirent			*dp;

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
		new_files.push_back(p);
	}

	return new_files;
}
