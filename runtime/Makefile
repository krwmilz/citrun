.ifdef SCV_PATH
error_SCV_PATH
.endif

CFLAGS += -fPIC -pthread -I../include
LIB = libruntime.so
SRCS = runtime.c
OBJS = $(SRCS:c=o)

$(LIB): $(OBJS)
	$(CC) $(CFLAGS) -shared -o $(LIB) $(OBJS)

clean:
	rm -f $(OBJS) $(LIB)

depend:
	mkdep $(CFLAGS) $(SRCS)
