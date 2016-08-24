#include "process_file.h"

#include <sys/types.h>

#include <dirent.h>		// DIR, opendir, readdir
#include <unordered_set>
#include <vector>

class ProcessDir {
public:
	ProcessDir();
	~ProcessDir();
	void	scan();

	std::vector<ProcessFile> m_procfiles;

private:
	const char	*m_procdir;
	DIR		*m_dirp;
	std::unordered_set<std::string> m_known_files;
};
