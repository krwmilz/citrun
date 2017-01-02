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
#include "inst_frontend.h"	// InstFrontend

#include <cstring>		// strcmp

#ifdef _WIN32
#include <windows.h>
#include <Shlwapi.h>		// PathFindFileNameA
#else /* _WIN32 */
#include <err.h>
#include <libgen.h>		// basename
#endif /* _WIN32 */


int
main(int argc, char *argv[])
{
	char		*base_name;
	bool		 is_citrun_inst = false;

#ifdef _WIN32
	// XXX: error checking
	base_name = PathFindFileNameA(argv[0]);
#else // _WIN32
	// Protect against argv[0] being an absolute path.
	if ((base_name = basename(argv[0])) == NULL)
		err(1, "basename");
#endif // _WIN32

	// Switch tool mode if we're called as 'citrun_inst'.
	if ((std::strcmp(base_name, "citrun_inst") == 0) ||
	    (std::strcmp(base_name, "citrun_inst.exe") == 0))
		is_citrun_inst = true;

	// Always re-search PATH for binary name (in non citrun_inst case).
	if (std::strcmp(argv[0], base_name) != 0)
		argv[0] = base_name;

	InstFrontend main(argc, argv, is_citrun_inst);
	main.process_cmdline();

	main.instrument();
	main.compile_instrumented();

	return 0;
}
