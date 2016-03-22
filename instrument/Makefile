PROG = scv_instrument
SRCS = main.cc instrumenter.cc

MKDEP = `llvm-config --cppflags`

CXXFLAGS += -std=c++11
CXXFLAGS += `llvm-config --cxxflags`
LDFLAGS += `llvm-config --ldflags`

# Clang has a circular dependencies here, use "linker group options" to avoid
LDADD += -Wl,--start-group \
	-lclangAST \
	-lclangAnalysis \
	-lclangBasic \
	-lclangDriver \
	-lclangEdit \
	-lclangFrontend \
	-lclangFrontendTool \
	-lclangLex \
	-lclangParse \
	-lclangRewriteCore \
	-lclangRewriteFrontend \
	-lclangSema \
	-lclangSerialization \
	-lclangTooling \
	-Wl,--end-group \

LDADD += `llvm-config --libs bitreader mcparser transformutils option --system-libs`

depend:
	# fucking thing doesn't work

.include <bsd.prog.mk>
