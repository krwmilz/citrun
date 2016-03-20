#ifndef TEXT_H
#define TEXT_H

#include <string>
#include <vector>

#include "af_unix.h"
#include "draw.h"

#include "demo-buffer.h"
#include "demo-font.h"

class RuntimeClient : public drawable {
public:
	RuntimeClient(af_unix *, demo_buffer_t *, demo_font_t *);

	void draw();
	void idle();
private:
	void read_file();

	af_unix *socket;
	demo_buffer_t *buffer;
	demo_font_t *font;

	uint64_t num_tus;
	std::string file_name;
	uint64_t num_lines;

	std::vector<std::string> source_file_contents;
	std::vector<uint64_t> execution_counts;
};

#endif
