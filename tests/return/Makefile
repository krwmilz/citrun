BIN = prog
SRCS = return.c
OBJS = $(SRCS:c=o)

$(BIN): $(OBJS)
	$(CC) -o $(BIN) $(OBJS) $(LDLIBS)

diff:
	diff -u return.c.inst{_good,}

.include "../Makefile.test"
