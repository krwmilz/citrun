#include <pthread.h>
#include <stdio.h>

/* these symbols are guaranteed to exist because of instrumentation */
extern unsigned int lines[];
extern int size;

void *
control_thread(void *arg)
{
	// printf("control thread says %i bytes!\n", size);
}

__attribute__((constructor))
static void runtime_init()
{
	pthread_t tid;

	pthread_create(&tid, NULL, control_thread, NULL);
}
