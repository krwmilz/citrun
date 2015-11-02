BIN = prog
SRCS = while.c
OBJS = $(SRCS:c=o)

$(BIN): $(OBJS)
	$(CC) -o $(BIN) $(OBJS) $(LDLIBS)

diff:
	diff -u while.c.inst_good while.c.inst

.include "../Makefile.test"
