#include <err.h>
#include <pthread.h>
#include <stdio.h>
#include <string.h>
#include <sys/socket.h>		// AF_UNIX
#include <sys/un.h>		// sockaddr_un

#include <scv_global.h>

/* Entry point into an instrumented application */
extern struct scv_node node0;

void *
walk_nodes(void *arg)
{
	int i;

	printf("%s: alive", __func__);

	struct scv_node *temp = &node0;
	while (temp) {
		printf("filename = %s\n", temp->file_name);
		printf("size = %u\n", temp->size);
		for (i = 0; i < temp->size; i++) {
			printf("  ln %i = %u\n", i, temp->lines_ptr[i]);
		}
		temp = temp->next;
	}

	printf("%s: done", __func__);
}

void *
control_thread(void *arg)
{
	int fd;
	int i;

	fd = socket(AF_UNIX, SOCK_STREAM, 0);
	if (fd == -1)
		err(1, "socket");

	struct sockaddr_un addr;
	memset(&addr, 0, sizeof(addr));
	addr.sun_family = AF_UNIX;
	strncpy(addr.sun_path, "socket", sizeof(addr.sun_path) - 1);

	return;
	// fprintf(stderr, "%s: initialized\n", __func__);

	while (1) {
		if (connect(fd, (struct sockaddr *)&addr, sizeof(addr)))
			err(1, "connect");
	}
}

__attribute__((constructor))
static void runtime_init()
{
	pthread_t tid;
	pthread_create(&tid, NULL, control_thread, NULL);
}
