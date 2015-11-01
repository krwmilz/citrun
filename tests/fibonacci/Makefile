BIN = prog
SRCS = fib.c
OBJS = $(SRCS:c=o)

$(BIN): $(OBJS)
	$(CC) -o $(BIN) $(OBJS) $(LDLIBS)

diff:
	diff -u fib.c.inst fib.c.inst_good

.include "../Makefile.test"
