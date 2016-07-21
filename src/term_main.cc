#include <stdlib.h>	// exit
#include <ncurses.h>

#include "af_unix.h"
#include "runtime_conn.h"

int
main(int argc, char *argv[])
{
	int ch;
	af_unix listen_sock;

	listen_sock.set_listen();

	initscr();
	if (has_colors() == FALSE) {
		endwin();
		printf("Your terminal does not support color\n");
		exit(1);
	}
	start_color();
	init_pair(1, COLOR_RED, COLOR_BLACK);

	printw("Waiting for connection on /tmp/citrun-gl.socket\n");
	refresh();

	af_unix *client = listen_sock.accept();
	if (client == NULL)
		errx(1, "client was NULL");

	RuntimeProcess conn(*client);
	printw("program name: %s\n", conn.program_name.c_str());
	printw("program name: %s\n", conn.program_name.c_str());

	refresh();

	getch();
	endwin();

	return 0;
}
