PROG = scv_instrument
SRCS = main.cxx instrumenter.cxx

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

LDADD += `llvm-config --libs bitreader`
LDADD += `llvm-config --libs mcparser`
LDADD += `llvm-config --libs option`
LDADD += `llvm-config --system-libs`

.include <bsd.prog.mk>
