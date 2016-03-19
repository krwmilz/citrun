#ifndef TEXT_H
#define TEXT_H

#include <vector>

#include "af_unix.h"
#include "draw.h"

class text : public drawable {
public:
	text(af_unix *);

	void draw();
	void idle();
private:
	void read_file();

	af_unix *socket;

	uint64_t num_tus;
	std::string file_name;
	uint64_t num_lines;

	std::vector<std::string> source_file_contents;
	std::vector<uint64_t> execution_counts;
};

#endif
