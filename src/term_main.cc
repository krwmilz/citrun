//
// Original idea from Max Zunti.
//
#include <iostream>
#include <ncurses.h>
#include <queue>
#include <stdlib.h>	// exit
#include <time.h>	// clock_gettime, nanosleep

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
	init_pair(2, COLOR_YELLOW, COLOR_BLACK);
	init_pair(3, COLOR_RED, COLOR_BLACK);

	printw("Waiting for connection on /tmp/citrun.socket\n");
	refresh();

	af_unix *client = listen_sock.accept();
	if (client == NULL)
		errx(1, "client was NULL");

	RuntimeProcess conn(*client);

	int fps = 0.;
	int eps = 0;

	int offset = 0;
	int size_y, size_x;
	getmaxyx(stdscr, size_y, size_x);

	struct timespec floating_avg;
	struct timespec last_frame;

	std::queue<struct timespec> frame_deltas;
	struct timespec sleep = { 0, 1 * 1000 * 1000 * 1000 / 60 };

	clock_gettime(CLOCK_UPTIME, &last_frame);
	uint64_t total_executions = 0;

	while (1) {
		erase();
		conn.read_executions();

		auto &t = conn.translation_units[0];
		for (int i = offset; i < (size_y - 2); i++) {
			uint32_t e = t.execution_counts[i + 1];
			std::string l = t.source[i];

			total_executions += e;

			int color = 0;
			if (e > 10 * 1000)
				color = 1;
			else if (e > 1 * 1000)
				color = 2;
			else if (e > 0)
				color = 3;

			if (color != 0)
				attron(COLOR_PAIR(color));

			printw("%s\n", l.c_str());

			if (color != 0)
				attroff(COLOR_PAIR(color));
		}

		move(size_y - 1, 0);
		clrtoeol();

		printw("%s: [%i tus] [%i fps] [%i execs/s]\n",
			conn.program_name.c_str(), conn.num_tus, fps, eps);
		refresh();

		struct timespec tmp, delta;
		clock_gettime(CLOCK_UPTIME, &tmp);

		// Find out how long last frame took
		timespecsub(&tmp, &last_frame, &delta);
		last_frame = tmp;

		timespecadd(&floating_avg, &delta, &floating_avg);
		frame_deltas.push(delta);

		if (frame_deltas.size() > 60) {
			tmp = frame_deltas.front();
			frame_deltas.pop();
			timespecsub(&floating_avg, &tmp, &floating_avg);
		}

		fps = 60 * 1000 / (floating_avg.tv_sec * 1000 + floating_avg.tv_nsec / (1000 * 1000));
		// eps = total_executions * 1000 / delta_ms;
		// total_executions = 0;

		struct timespec one = { 1, 0 };
		struct timespec shift = { 0, 1000 * 1000 };
		if (timespeccmp(&floating_avg, &one, <))
			timespecadd(&sleep, &shift, &sleep);
		else
			timespecsub(&sleep, &shift, &sleep);

		nanosleep(&sleep, NULL);
	}

	endwin();

	return 0;
}
