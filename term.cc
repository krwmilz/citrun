//
// Original idea from Max Zunti.
//
#include <cassert>
#include <csignal>	// sigaction
#include <cstdlib>	// exit
#include <err.h>	// errx
#include <iostream>
#include <ncurses.h>
#include <queue>
#include <time.h>	// clock_gettime, nanosleep

#include "process_dir.h" // ProcessDir
#include "shm.h"

class CursesViewer {
public:
	CursesViewer(ProcessDir &pdir);
	void loop();

private:
	int get_keyboard();
	void draw();
	void print_statusbar();
	void update_execs();
	void update_sleep();

	ProcessDir	 m_pdir;
	ProcessFile	*m_cur_pfile;
	std::queue<uint64_t> m_execution_history;
	std::queue<struct timespec> m_frame_deltas;
	TranslationUnit	 m_cur_tu;
	struct timespec	 m_floating_avg;
	struct timespec	 m_last_frame;
	struct timespec	 m_sleep;
	uint64_t	 m_exec_floating_avg;
	uint64_t	 m_total_executions;
	int		 m_fps;
	int		 m_eps;
	int		 m_tu;
	int		 m_offset;
	int		 m_size_y;
	int		 m_size_x;
};

CursesViewer::CursesViewer(ProcessDir &pdir) :
	m_pdir(pdir),
	m_floating_avg({ 1, 0 }),
	m_sleep({ 0, 1 * 1000 * 1000 * 1000 / 66 }),
	m_exec_floating_avg(0),
	m_total_executions(0),
	m_fps(0),
	m_eps(0),
	m_tu(0),
	m_offset(0)
{
	getmaxyx(stdscr, m_size_y, m_size_x);

	m_cur_pfile = &m_pdir.m_procfiles[0];
	m_cur_tu = m_cur_pfile->m_tus[0];

	struct timespec one_thirtythird = { 0, 1 * 1000 * 1000 * 1000 / 33 };
	for (int i = 0; i < 33; i++) {
		m_frame_deltas.push(one_thirtythird);
		m_execution_history.push(0);
	}
}

void
CursesViewer::loop()
{
#ifndef __APPLE__
	clock_gettime(CLOCK_UPTIME, &m_last_frame);
#endif

	// Make getch() non-blocking.
	nodelay(stdscr, true);

	while (1) {
		assert(m_frame_deltas.size() == 33);
		assert(m_execution_history.size() == 33);

		erase();
		if (get_keyboard())
			return;
		draw();
		update_execs();
		update_sleep();
	}
}

int
CursesViewer::get_keyboard()
{
	// Non-blocking due to nodelay().
	int ch = getch();

	if (ch == 'q')
		return 1;
	else if (ch == 'l' && m_tu < (m_cur_pfile->m_tus.size() - 1))
		m_tu++;
	else if (ch == 'h' && m_tu > 0)
		m_tu--;

	m_cur_tu = m_cur_pfile->m_tus[m_tu];

	if (ch == 'j' && m_offset < (m_cur_tu.num_lines - m_size_y - 1))
		m_offset++;
	else if (ch == 'k' && m_offset > 0)
		m_offset--;

	return 0;
}

void
CursesViewer::draw()
{
	int upper_bound = m_size_y - 2 + m_offset;

	for (int i = m_offset; i < upper_bound && i < m_cur_tu.num_lines; i++) {
		uint64_t e = m_cur_tu.exec_counts[i] - m_cur_tu.exec_counts_last[i];

		std::string l = m_cur_tu.source[i];

		m_total_executions += e;

		int color = 0;
		if (e > 100000)
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

	m_cur_pfile->save_executions();
	print_statusbar();
	refresh();
}

void
CursesViewer::print_statusbar()
{
	move(m_size_y - 1, 0);
	clrtoeol();

	for (int i = 1; i <= 5; i++) {
		attron(COLOR_PAIR(i));
		printw("<<");
		attroff(COLOR_PAIR(i));
	}

	printw(" [%s] [%s] [%i/%i] [%i fps] [%ik execs/s]",
		m_cur_pfile->m_progname.c_str(),
		m_cur_tu.comp_file_path.c_str(),
		m_tu + 1, m_cur_pfile->m_tus.size(),
		m_fps,
		m_eps / 1000);

	printw("\n");
}

void
CursesViewer::update_execs()
{
	// Push on new data and pop old data off. Subtracts the oldest
	// execution count from the floating average.
	m_exec_floating_avg += m_total_executions;
	m_execution_history.push(m_total_executions);

	m_exec_floating_avg -= m_execution_history.front();
	m_execution_history.pop();

	m_eps = m_exec_floating_avg / 33;
	m_total_executions = 0;
}

void
CursesViewer::update_sleep()
{
#ifndef __APPLE__
	struct timespec tmp, delta;
	struct timespec one = { 1, 0 };
	struct timespec shift = { 0, 50 * 1000 };

	// Get last frames duration and update last_frame time.
	clock_gettime(CLOCK_UPTIME, &tmp);
	timespecsub(&tmp, &m_last_frame, &delta);
	m_last_frame = tmp;

	// Pop oldest off and push newest on to frame_delta's queue.
	m_frame_deltas.push(delta);
	tmp = m_frame_deltas.front();
	m_frame_deltas.pop();

	// Remove oldest time and add newest time to floating_avg.
	timespecsub(&m_floating_avg, &tmp, &m_floating_avg);
	timespecadd(&m_floating_avg, &delta, &m_floating_avg);

	m_fps = 33 * 1000 / (m_floating_avg.tv_sec * 1000 + m_floating_avg.tv_nsec / (1000 * 1000));

	if (timespeccmp(&m_floating_avg, &one, <))
		// We're executing too fast. Increase sleep.
		timespecadd(&m_sleep, &shift, &m_sleep);
	else if (timespeccmp(&m_floating_avg, &one, !=) && timespeccmp(&m_sleep, &shift, >))
		// Floating avg is > 1.0 but we can still subtract at
		// least shift.
		timespecsub(&m_sleep, &shift, &m_sleep);

#endif
	nanosleep(&m_sleep, NULL);
}

int
main(int argc, char *argv[])
{
	ProcessDir pdir;

	initscr();
	if (has_colors() == FALSE) {
		endwin();
		printf("Your terminal does not support color\n");
		std::exit(1);
	}
	start_color();
	init_pair(1, COLOR_RED, COLOR_BLACK);
	init_pair(2, COLOR_YELLOW, COLOR_BLACK);
	init_pair(3, COLOR_GREEN, COLOR_BLACK);
	init_pair(4, COLOR_CYAN, COLOR_BLACK);
	init_pair(5, COLOR_MAGENTA, COLOR_BLACK);

	printw(">> Welcome to C It Run!\n");
	printw(">> Waiting for programs..\n");

	refresh();

	pdir.scan();
	while (pdir.m_procfiles.size() == 0) {
		sleep(1);
		pdir.scan();
	}

	CursesViewer viewer(pdir);
	viewer.loop();

	endwin();

	return 0;
}
