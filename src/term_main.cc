/*
 * Original idea for this program from Max Zunti.
 */
#include <iostream>
#include <ncurses.h>
#include <stdlib.h>	// exit

#include "af_unix.h"
#include "runtime_conn.h"

int
main(int argc, char *argv[])
{
	af_unix listen_sock;
	listen_sock.set_listen();

	initscr();
	if (has_colors() == FALSE) {
		endwin();
		printf("Your terminal does not support color\n");
		exit(1);
	}
	start_color();
	init_pair(1, COLOR_GREEN, COLOR_BLACK);

	printw("Waiting for connection on /tmp/citrun-gl.socket\n");
	refresh();

	af_unix *client = listen_sock.accept();
	if (client == NULL)
		errx(1, "client was NULL");

	RuntimeProcess conn(*client);

	while (1) {
		erase();

		conn.read_executions();

		auto &t = conn.translation_units[0];
		std::vector<uint32_t>::iterator e = t.execution_counts.begin();
		std::vector<std::string>::iterator l = t.source.begin();

		e++;
		while (e != t.execution_counts.end() && l != t.source.end()) {
			if (*e > 10 * 1000)
				attron(COLOR_PAIR(1));
			printw("%s\n", l->c_str());
			if (*e > 10 * 1000)
				attroff(COLOR_PAIR(1));
			e++;
			l++;
		}

		refresh();
	}

	printw("program name: %s\n", conn.program_name.c_str());
	printw("num tus: %i\n", conn.num_tus);

	getch();
	endwin();

	return 0;
}
