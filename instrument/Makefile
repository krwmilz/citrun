PROG = scv_instrument
SRCS = main.cxx instrumenter.cxx

CXX = eg++
CXXFLAGS += -std=c++11
CXXFLAGS += -I/usr/local/include
CXXFLAGS += -D__STDC_LIMIT_MACROS -D__STDC_CONSTANT_MACROS
CXXFLAGS += -fno-rtti -Wall
# CXXFLAGS += -ggdb -DDEBUG

# OpenBSD has it's third part libraries here
LDFLAGS += -L/usr/local/lib

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
	-lLLVMOption \
	-lLLVMMCParser \
	-lLLVMTransformUtils \
	-lLLVMMC \
	-lLLVMBitReader \
	-lLLVMCore \
	-lLLVMSupport \
	-lpthread -lz

.include <bsd.prog.mk>
