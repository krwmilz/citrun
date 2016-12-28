//
// Copyright (c) 2016 Kyle Milz <kyle@0x30.net>
//
// Permission to use, copy, modify, and distribute this software for any
// purpose with or without fee is hereby granted, provided that the above
// copyright notice and this permission notice appear in all copies.
//
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
// WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
// ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
// WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
// ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
// OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
//
#include <cstring>		// strcmp

#include "inst_frontend.h"	// InstFrontend

int
main(int argc, char *argv[])
{
	int ret;

	if (argc == 2 && (std::strcmp(argv[1], "--print-share") == 0)) {
		std::cout << CITRUN_SHARE;
		return 0;
	}

	InstFrontend main(argc, argv);
	main.process_cmdline();

	main.instrument();

	ret = main.fork_compiler();
	main.restore_original_src();

	if (ret)
		// Rewritten compile failed. Run again without modified src.
		main.exec_compiler();
	return 0;
}
