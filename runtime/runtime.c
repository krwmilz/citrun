#include <pthread.h>
#include <stdio.h>

void *
control_thread(void *arg)
{
	// printf("control thread alive!\n");
}

__attribute__((constructor))
static void runtime_init()
{
	pthread_t tid;

	pthread_create(&tid, NULL, control_thread, NULL);
}
