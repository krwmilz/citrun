//
// Original idea from Max Zunti.
//
#include <cassert>
#include <iostream>
#include <ncurses.h>
#include <queue>
#include <stdlib.h>	// exit
#include <time.h>	// clock_gettime, nanosleep

#include "af_unix.h"
#include "runtime.hh"

void
draw_source(RuntimeProcess &conn)
{

	int fps = 0.;
	int eps = 0;

	int tu = 0;
	int offset = 0;
	int size_y, size_x;
	getmaxyx(stdscr, size_y, size_x);

	struct timespec floating_avg = { 1, 0 };
	uint64_t exec_floating_avg = 0;
	struct timespec last_frame;

	uint64_t total_executions = 0;
	std::queue<uint64_t> execution_history;

	struct timespec sleep = { 0, 1 * 1000 * 1000 * 1000 / 50 };
	std::queue<struct timespec> frame_deltas;

	for (int i = 0; i < 50; i++) {
		frame_deltas.push(sleep);
		execution_history.push(0);
	}

	sleep = { 0, 1 * 1000 * 1000 * 1000 / 100 };

	clock_gettime(CLOCK_UPTIME, &last_frame);

	// Make getch() non-blocking.
	nodelay(stdscr, true);

	while (1) {
		assert(frame_deltas.size() == 50);
		assert(execution_history.size() == 50);

		erase();
		conn.read_executions();

		int tus_with_execs = 0;
		for (auto &t : conn.m_tus)
			tus_with_execs += t.has_execs;

		auto &t = conn.m_tus[tu];
		total_executions = 0;
		for (int i = offset; i < (size_y - 2 + offset) && i < t.num_lines; i++) {
			uint32_t e = t.exec_diffs[i + 1];
			std::string l = t.source[i];

			total_executions += e;

			int color = 0;
			if (e > 100000 )
				color = 5;
			else if (e > 10000)
				color = 4;
			else if (e > 1000 )
				color = 3;
			else if (e > 100)
				color = 2;
			else if (e > 0)
				color = 1;

			if (color != 0)
				attron(COLOR_PAIR(color));

			printw("%s\n", l.c_str());

			if (color != 0)
				attroff(COLOR_PAIR(color));
		}

		// Non-blocking due to nodelay() above.
		int ch = getch();
		if (ch == 'j' && offset < (t.num_lines - size_y - 1))
			offset++;
		else if (ch == 'k' && offset > 0)
			offset--;
		else if (ch == 'l' && tu < (conn.m_num_tus - 1))
			tu++;
		else if (ch == 'h' && tu > 0)
			tu--;

		move(size_y - 1, 0);
		clrtoeol();

		printw("%s [%s (%i/%i)] [%i fps] [%ik execs/s (%i)] [%i us]",
			conn.m_progname.c_str(), "", //t.file_name.c_str(),
			tu + 1, conn.m_num_tus, fps, eps / 1000, tus_with_execs,
			sleep.tv_sec + sleep.tv_nsec / 1000);
		for (int i = 1; i <= 5; i++) {
			attron(COLOR_PAIR(i));
			printw("<<");
			attroff(COLOR_PAIR(i));
		}
		printw("\n");
		refresh();

		struct timespec tmp, delta;

		// Get last frames duration and update last_frame time.
		clock_gettime(CLOCK_UPTIME, &tmp);
		timespecsub(&tmp, &last_frame, &delta);
		last_frame = tmp;

		// Pop oldest off and push newest on to frame_delta's queue.
		frame_deltas.push(delta);
		tmp = frame_deltas.front();
		frame_deltas.pop();

		// Remove oldest time and add newest time to floating_avg.
		timespecsub(&floating_avg, &tmp, &floating_avg);
		timespecadd(&floating_avg, &delta, &floating_avg);

		// Add the newest execution count to the floating average.
		exec_floating_avg += total_executions;

		// Push on new data and pop old data off. Subtracts the oldest
		// execution count from the floating average.
		execution_history.push(total_executions);
		exec_floating_avg -= execution_history.front();
		execution_history.pop();

		fps = 50 * 1000 / (floating_avg.tv_sec * 1000 + floating_avg.tv_nsec / (1000 * 1000));
		eps = exec_floating_avg / 50;

		struct timespec one = { 1, 0 };
		struct timespec zero = { 0, 0 };
		struct timespec shift = { 0, 50 * 1000 };
		if (timespeccmp(&floating_avg, &one, <))
			// We're executing too fast. Increase sleep.
			timespecadd(&sleep, &shift, &sleep);
		else if (timespeccmp(&floating_avg, &one, !=) && timespeccmp(&sleep, &shift, >=))
			// Floating avg is > 1.0 but we can still subtract at
			// least shift.
			timespecsub(&sleep, &shift, &sleep);

		nanosleep(&sleep, NULL);
	}
}

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
	init_pair(1, COLOR_RED, COLOR_BLACK);
	init_pair(2, COLOR_YELLOW, COLOR_BLACK);
	init_pair(3, COLOR_GREEN, COLOR_BLACK);
	init_pair(4, COLOR_CYAN, COLOR_BLACK);
	init_pair(5, COLOR_MAGENTA, COLOR_BLACK);

	printw("Waiting for connection on /tmp/citrun.socket\n");
	refresh();

	af_unix *client = listen_sock.accept();
	if (client == NULL)
		errx(1, "client was NULL");

	RuntimeProcess conn(*client);
	draw_source(conn);

	endwin();

	return 0;
}
