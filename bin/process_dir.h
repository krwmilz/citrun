#include <sys/types.h>

#include <dirent.h>		// DIR, opendir, readdir
#include <string>
#include <unordered_set>
#include <vector>

class ProcessDir
{
	const char			*m_procdir;
	DIR				*m_dirp;
	std::unordered_set<std::string>	 m_known_files;

public:
	ProcessDir();
	std::vector<std::string>	 scan();
};
