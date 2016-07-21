#ifndef TEXT_H
#define TEXT_H
#include <string>
#include <vector>

#include "af_unix.h"

struct TranslationUnit {
	std::string file_name;
	uint32_t num_lines;
	uint32_t inst_sites;
	std::vector<uint64_t> execution_counts;
	std::vector<std::string> source;
};

class RuntimeProcess {
public:
	RuntimeProcess(af_unix &);
	void read_executions();

	std::string program_name;
	uint64_t num_tus;
	uint64_t lines_total;
	pid_t process_id;
	pid_t parent_process_id;
	pid_t process_group;
	std::vector<TranslationUnit> translation_units;
private:
	void read_source(struct TranslationUnit &);

	double y_margin;
	af_unix socket;
};

#endif
