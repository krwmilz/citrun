PROG = scv_viewer
SRCS = viewer.cxx text.cxx af_unix.cxx

CXX = eg++
CXXFLAGS += -std=c++11
CXXFLAGS += `pkg-config gl --cflags`
CXXFLAGS += `pkg-config glew --cflags`
CXXFLAGS += `pkg-config ftgl --cflags`

LDFLAGS += `pkg-config gl --libs`
LDFLAGS += `pkg-config glew --libs`
LDFLAGS += `pkg-config ftgl --libs`

LDADD += -lz -lglut

.include <bsd.prog.mk>
