PROG = scv_viewer
SRCS = viewer.cxx text.cxx af_unix.cxx

CXXFLAGS += -std=c++11
CXXFLAGS += `pkg-config gl glew ftgl --cflags`

LDFLAGS += `pkg-config gl glew ftgl --libs`
LDADD += -lstdc++ -lz -lglut

.include <bsd.prog.mk>
