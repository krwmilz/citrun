#include <err.h>
#include <pthread.h>
#include <stdio.h>
#include <string.h>
#include <sys/socket.h>		// AF_UNIX
#include <sys/un.h>		// sockaddr_un


/* guaranteed to exist at link time because of instrumentation */
extern unsigned int lines[];
extern int size;
extern const char file_name[];

void *
control_thread(void *arg)
{
	int fd;
	int i, set;

	printf("%s: file '%s' (%i bytes)\n", __func__, file_name, size);

	fd = socket(AF_UNIX, SOCK_STREAM, 0);
	if (fd == -1)
		err(1, "socket");

	struct sockaddr_un addr;
	memset(&addr, 0, sizeof(addr));
	addr.sun_family = AF_UNIX;
	strncpy(addr.sun_path, "socket", sizeof(addr.sun_path) - 1);

	printf("%s: initialized\n", __func__);

	while (1) {
		if (connect(fd, (struct sockaddr *)&addr, sizeof(addr)))
			warn("connect");

		set = 0;
		for (i = 0; i < size; i++)
			if (lines[i] == 1) {
				set++;
				lines[i] = 0;
			}

		printf("%i lines set\n", set);

		sleep(1);
	}
}

__attribute__((constructor))
static void runtime_init()
{
	pthread_t tid;

	pthread_create(&tid, NULL, control_thread, NULL);
}
