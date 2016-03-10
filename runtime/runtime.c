#include <err.h>
#include <pthread.h>
#include <stdio.h>
#include <string.h>
#include <sys/socket.h>		// AF_UNIX
#include <sys/un.h>		// sockaddr_un

#include <scv_global.h>

/* Entry point into an instrumented application */
extern struct scv_node node0;

void
walk_nodes()
{
	int i;

	fprintf(stderr, "%s: alive", __func__);

	/* Copy node0, don't use it directly */
	struct scv_node temp = node0;
	while (temp.size != 0) {
		printf("filename = %s\n", temp.file_name);
		printf("size = %u\n", temp.size);
		for (i = 0; i < temp.size; i++) {
			fprintf(stderr, "  ln %i = %u\n", i, temp.lines_ptr[i]);
		}
		temp = *temp.next;
	}

	fprintf(stderr, "%s: done", __func__);
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
	strncpy(addr.sun_path, "/tmp/viewer_test.socket", sizeof(addr.sun_path) - 1);

	// fprintf(stderr, "%s: initialized\n", __func__);

	if (connect(fd, (struct sockaddr *)&addr, sizeof(addr))) {
		// warn("connect");
		return 0;
	}

	uint8_t version;
	uint8_t msg_type;
	read(fd, version, 1);
	read(fd, msg_type, 1);

	if (version != 0)
		err(1, "version != 0");

	if (msg_type == 0)
		walk_nodes();
}

__attribute__((constructor))
static void runtime_init()
{
	pthread_t tid;
	pthread_create(&tid, NULL, control_thread, NULL);
}
