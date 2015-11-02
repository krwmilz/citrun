BIN = prog
SRCS = if.c
OBJS = $(SRCS:c=o)

$(BIN): $(OBJS)
	$(CC) -o $(BIN) $(OBJS) $(LDLIBS)

diff:
	diff -u if.c.inst_good if.c.inst

.include "../Makefile.test"
