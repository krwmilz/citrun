# $OpenBSD$

COMMENT =		see your source code run

DISTNAME =		citrun-0
REVISION =		1
CATEGORIES =		devel

HOMEPAGE =		http://citrun.com

# BSD
PERMIT_PACKAGE_CDROM =	Yes

MASTER_SITES =		http://git.0x30.net/

WANTLIB +=		GL GLU GLEW glut c freetype m pthread z

SHARED_LIBS +=		scv		0.0 # 0.0

# -std=c++11
MODULES =		gcc4
MODGCC4_ARCHS =		*
MODGCC4_LANGS =		c++

LIB_DEPENDS =		graphics/freeglut \
			graphics/glew
BUILD_DEPENDS =		devel/jam \
			devel/llvm

do-build:
	cd ${WRKSRC} && ${SETENV} ${MAKE_ENV} jam

do-install:
	cd ${WRKSRC} && ${SETENV} ${MAKE_ENV} ${ALL_FAKE_FLAGS} jam install

.include <bsd.port.mk>
