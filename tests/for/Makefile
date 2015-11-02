BIN = prog
SRCS = for.c
OBJS = $(SRCS:c=o)

$(BIN): $(OBJS)
	$(CC) -o $(BIN) $(OBJS) $(LDLIBS)

diff:
	diff -u for.c.inst_good for.c.inst

.include "../Makefile.test"
