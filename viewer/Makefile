PROG = scv_viewer

SRCS = main.cc \
       runtime_client.cc \
       af_unix.cc \
       view.cc \
       demo-atlas.cc \
       demo-buffer.cc \
       demo-font.cc \
       demo-glstate.cc \
       demo-shader.cc \
       matrix4x4.c \
       trackball.c

CXXFLAGS += -std=c++11
CXXFLAGS += `pkg-config gl glew freetype2 --cflags` -I/usr/local/include

LDFLAGS += `pkg-config gl glew freetype2 --libs`
LDADD += -lstdc++ -lglut glyphy/libglyphy.a

.include <bsd.prog.mk>
