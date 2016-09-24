#include <sys/types.h>

#include <dirent.h>		// DIR, opendir, readdir
#include <unordered_set>
#include <vector>

class ProcessDir {
public:
	ProcessDir();
	std::vector<std::string>	*scan();

private:
	const char			*m_procdir;
	DIR				*m_dirp;
	std::unordered_set<std::string>	 m_known_files;
};
