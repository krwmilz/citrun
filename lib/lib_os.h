/*
 * Copyright (c) 2017 Kyle Milz <kyle@0x30.net>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */


/*
 * Extend the length of the file descriptor given by the first argument by at
 * least the number of bytes given as the second argument.
 *
 * Returns a pointer to the beginning of the newly allocated region on success.
 */
void	*citrun_extend(int, size_t);

/*
 * Creates a new semi random file name, opens it and returns the descriptor.
 * If the CITRUN_PROCDIR environment variable is set its value is prefixed to
 * the file name otherwise an operating system specific prefix is used.
 *
 * Returns the descriptor number on success.
 */
int	 citrun_open_fd();

/*
 * Takes a pointer to `struct citrun_header` and fills in as many header fields
 * as possible.
 */
void	 citrun_os_info(struct citrun_header *);

/*
 * Checks if the global `citrun_gl.lock` file is in the directory given by
 * CITRUN_PROCDIR if it exists. If CITRUN_PROCDIR does not exist an operating
 * system specific location is used instead.
 *
 * If no lock file exists, a viewer is started.
 */
void	 citrun_start_viewer();
