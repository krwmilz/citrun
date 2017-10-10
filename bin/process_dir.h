#include <sys/types.h>

#include <dirent.h>		// DIR, opendir, readdir
#include <string>
#include <unordered_set>
#include <vector>


namespace citrun {

class process_dir
{
	const char			*m_procdir;
	DIR				*m_dirp;
	std::unordered_set<std::string>	 m_known_files;

public:
	process_dir();
	std::vector<std::string>	 scan();
};

} // namespace citrun
