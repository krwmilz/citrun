PROG = scv_viewer

SRCS = main.cxx \
       runtime_client.cxx \
       af_unix.cxx \
       view.cxx \
       demo-atlas.cxx \
       demo-buffer.cxx \
       demo-font.cxx \
       demo-glstate.cxx \
       demo-shader.cxx \
       matrix4x4.c \
       trackball.c

CXXFLAGS += -std=c++11
CXXFLAGS += `pkg-config gl glew freetype2 --cflags` -I/usr/local/include

LDFLAGS += `pkg-config gl glew freetype2 --libs`
LDADD += -lstdc++ -lz -lglut glyphy/libglyphy.a

.include <bsd.prog.mk>
