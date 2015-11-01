BIN = prog
SRCS = hello.c
OBJS = $(SRCS:c=o)

$(BIN): $(OBJS)
	$(CC) -o $(BIN) $(OBJS) $(LDLIBS)

diff:
	diff -u hello.c.inst hello.c.inst_good

.include "../Makefile.test"
