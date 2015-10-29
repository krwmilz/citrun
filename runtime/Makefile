CFLAGS += -fPIC -pthread
LIB = libruntime.so
SRCS = runtime.c
OBJS = $(SRCS:c=o)

$(LIB): $(OBJS)
	$(CC) -shared -o $(LIB) $(OBJS)

clean:
	rm -f $(OBJS) $(LIB)

depend:
	mkdep $(CFLAGS) $(SRCS)
