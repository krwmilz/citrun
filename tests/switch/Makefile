BIN = prog
SRCS = switch.c
OBJS = $(SRCS:c=o)

$(BIN): $(OBJS)
	$(CC) -o $(BIN) $(OBJS) $(LDLIBS)

diff:
	diff -u switch.c.inst{_good,}

.include "../Makefile.test"
