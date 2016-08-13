# $OpenBSD$

COMMENT =		see citrun run

PKGNAME =		ccitrunrun-0.0
DISTNAME =		citrun-0.0
CATEGORIES =		devel

HOMEPAGE =		http://cit.run

# BSD
PERMIT_PACKAGE_CDROM =	Yes

MASTER_SITES =		${HOMEPAGE}/

WANTLIB +=		GL GLU GLEW glut c freetype m pthread z

# -std=c++11
MODULES =		gcc4
MODGCC4_ARCHS =		*
MODGCC4_LANGS =		c++

LIB_DEPENDS =		graphics/freeglut \
			graphics/glew

BUILD_DEPENDS =		devel/jam \
			devel/llvm

do-build:
	cd ${WRKSRC} && sed -i \
		-e "s,struct citrun_node,struct ccitrunrun_node," \
		-e "s,citrun_node_add,ccitrunrun_node_add," \
		-e "s,citrun_major,ccitrunrun_major,g" \
		-e "s,citrun_minor,ccitrunrun_minor,g" \
		src/runtime.h src/runtime.c \
		src/inst_action.cc src/inst_main.cc src/runtime_proc.cc
	cd ${WRKSRC} && sed -i \
		-e "s,citrun-inst,ccitrunrun-inst," \
		-e "s,citrun-term,ccitrunrun-term," \
		-e "s,citrun-gl,ccitrunrun-gl," \
		-e "s,libcitrun,libccitrunrun," \
		Jamrules src/runtime.c src/Jamfile src/inst_main.cc src/check.in
	cd ${WRKSRC} && ${SETENV} ${MAKE_ENV} jam -j4

do-test:
	cd ${WRKSRC} && prove

do-install:
	cd ${WRKSRC} && ${SETENV} ${MAKE_ENV} ${ALL_FAKE_FLAGS} jam install

.include <bsd.port.mk>
