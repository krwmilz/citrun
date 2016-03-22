#ifndef TEXT_H
#define TEXT_H

#include <string>
#include <vector>

#include "af_unix.h"
#include "draw.h"

#include "demo-buffer.h"
#include "demo-font.h"

struct TranslationUnit {
	std::string file_name;
	uint64_t num_lines;
	std::vector<uint64_t> execution_counts;
};

class RuntimeClient : public drawable {
public:
	RuntimeClient(af_unix *, demo_buffer_t *, demo_font_t *);

	void draw();
	void idle();
private:
	void read_file(std::string, glyphy_point_t);

	pid_t process_id;
	pid_t parent_process_id;
	pid_t process_group;

	af_unix *socket;
	demo_buffer_t *buffer;
	demo_font_t *font;

	std::vector<TranslationUnit> translation_units;
};

#endif
