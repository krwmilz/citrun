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

CPPFLAGS += `pkg-config gl glew freetype2 --cflags`
CPPFLAGS += -I/usr/local/include
CXXFLAGS += -std=c++11

LDFLAGS += `pkg-config gl glew freetype2 --libs`
LDADD += -lstdc++ -lm -lglut glyphy/libglyphy.a

.include <bsd.prog.mk>
