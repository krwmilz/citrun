BIN = prog
SRCS = fib.c
OBJS = $(SRCS:c=o)

$(BIN): $(OBJS)
	$(CC) -o $(BIN) $(OBJS) $(LDLIBS)

test:
	sh test.sh

diff:
	diff -u fib.c.inst fib.c.inst_good

clean:
	rm -f $(OBJS) $(BIN) *.{backup,inst}
