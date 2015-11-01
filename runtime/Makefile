.ifdef SCV_PATH
error_SCV_PATH
.endif

CFLAGS += -fPIC -pthread
LIB = libruntime.a
SRCS = runtime.c
OBJS = $(SRCS:c=o)

$(LIB): $(OBJS)
	$(AR) cr $(LIB) $(OBJS)

clean:
	rm -f $(OBJS) $(LIB)

depend:
	mkdep $(CFLAGS) $(SRCS)
