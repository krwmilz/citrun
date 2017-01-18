# $OpenBSD$

COMMENT =		see your source code run

DISTNAME =		citrun
PKGNAME =		citrun-0.0
CATEGORIES =		devel

HOMEPAGE =		http://cit.run

# BSD
PERMIT_PACKAGE_CDROM =	Yes

MASTER_SITES =		${HOMEPAGE}/

WANTLIB +=		curses GL GLU GLEW glfw c freetype m pthread z

# -std=c++11
MODULES =		gcc4
MODGCC4_ARCHS =		*
MODGCC4_LANGS =		c++

LIB_DEPENDS =		graphics/glew \
			graphics/glfw

BUILD_DEPENDS =		devel/jam \
			devel/llvm

TEST_DEPENDS =		devel/p5-Expect

do-configure:
	cd ${WRKSRC} && ${SETENV} ${MAKE_ENV} ./configure

do-build:
	cd ${WRKSRC} && ${SETENV} ${MAKE_ENV} jam -q

do-install:
	cd ${WRKSRC} && ${SETENV} ${MAKE_ENV} ${ALL_FAKE_FLAGS} jam install

.include <bsd.port.mk>
