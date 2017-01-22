/*
 * Copyright (c) 2016 Kyle Milz <kyle@0x30.net>
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
#include <stdlib.h>		/* exit */
#include <stdio.h>		/* fprintf, stderr */
#include <string.h>		/* strncpy */

#include "libP.h"		/* lib.h, citrun_extend, citrun_open_fd */


/*
 * Extends the memory mapping and puts a struct citrun_header on top of it.
 */
static struct citrun_header *
citrun_add_header()
{
	struct citrun_header	*new_header;

	new_header = citrun_extend(sizeof(struct citrun_header));

	strncpy(new_header->magic, "ctrn", sizeof(new_header->magic));
	new_header->major = citrun_major;
	new_header->minor = citrun_minor;

	/* Fill in os specific information in header. */
	citrun_os_info(new_header);

	return new_header;
}

/*
 * Public Interface.
 *
 * Copies n into the shared memory file and then points n->data to a region of
 * memory located right after n that's at least 8 * n->size large.
 * Exits on failure.
 */
void
citrun_node_add(unsigned int major, unsigned int minor, struct citrun_node *n)
{
	size_t				 sz;
	struct citrun_node		*new;
	static struct citrun_header	*header = NULL;

	/* Binary compatibility between versions not guaranteed. */
	if (major != citrun_major || minor != citrun_minor) {
		fprintf(stderr, "libcitrun %i.%i: incompatible version %i.%i.\n"
			"Try cleaning and rebuilding your project.\n",
			citrun_major, citrun_minor, major, minor);
		exit(1);
	}

	if (header == NULL) {
		citrun_open_fd();
		header = citrun_add_header();
	}

	/* Allocate enough room for node and live execution buffers. */
	sz = sizeof(struct citrun_node);
	sz += n->size * sizeof(unsigned long long);
	new = citrun_extend(sz);

	/* Increment accumulation fields in header. */
	header->units++;
	header->loc += n->size;

	/* Copy these fields from incoming node verbatim. */
	new->size = n->size;
	strncpy(new->comp_file_path, n->comp_file_path, CITRUN_PATH_MAX);
	strncpy(new->abs_file_path,  n->abs_file_path, CITRUN_PATH_MAX);
	new->comp_file_path[CITRUN_PATH_MAX - 1] = '\0';
	new->abs_file_path[CITRUN_PATH_MAX - 1] = '\0';

	/* Set incoming nodes data pointer to allocated space after struct. */
	n->data = (unsigned long long *)(new + 1);
}
