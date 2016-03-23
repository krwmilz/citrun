LIB = scv
SRCS = runtime.c

SHLIB_MAJOR = 0
SHLIB_MINOR = 0

CFLAGS += -pthread

# OS X linker will not do runtime symbol lookup by default
LDFLAGS += -Wl,-U,__scv_node0
LDADD += -pthread

NO_PROFILE = 1
NOPROFILE = 1
.include <bsd.lib.mk>
