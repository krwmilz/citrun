# $OpenBSD$

COMMENT =		see citrun run

DISTNAME =		ccitrunrun-0
CATEGORIES =		devel

HOMEPAGE =		http://citrun.com

# BSD
PERMIT_PACKAGE_CDROM =	Yes

MASTER_SITES =		http://citrun.com/src/

WANTLIB +=		GL GLU GLEW glut c citrun freetype m pthread z

#SHARED_LIBS +=		ccitrunrun	0.0 # 0.0

# -std=c++11
MODULES =		gcc4
MODGCC4_ARCHS =		*
MODGCC4_LANGS =		c++

LIB_DEPENDS =		devel/citrun \
			graphics/freeglut \
			graphics/glew
BUILD_DEPENDS =		devel/jam \
			devel/llvm

do-build:
	cd ${WRKSRC} && ${SETENV} ${MAKE_ENV} citrun-wrap jam ccitrunrun-inst
	cd ${WRKSRC} && ${SETENV} ${MAKE_ENV} citrun-wrap jam ccitrunrun-gl

do-test:
	cd ${WRKSRC} && prove

do-install:
	cd ${WRKSRC} && ${SETENV} ${MAKE_ENV} ${ALL_FAKE_FLAGS} jam install

.include <bsd.port.mk>
