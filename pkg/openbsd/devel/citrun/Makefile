# $OpenBSD$

COMMENT =		see your source code run

DISTNAME =		citrun-0.0
CATEGORIES =		devel

HOMEPAGE =		http://cit.run

# BSD
PERMIT_PACKAGE_CDROM =	Yes

MASTER_SITES =		${HOMEPAGE}/src/

WANTLIB +=		GL GLU GLEW glut c freetype m pthread z

# -std=c++11
MODULES =		gcc4
MODGCC4_ARCHS =		*
MODGCC4_LANGS =		c++

LIB_DEPENDS =		graphics/freeglut \
			graphics/glew

BUILD_DEPENDS =		devel/jam \
			devel/llvm

TEST_DEPENDS =		devel/p5-Expect \
			devel/p5-List-MoreUtils \
			devel/p5-Test-Differences \
			sysutils/p5-File-Which

do-build:
	cd ${WRKSRC} && ${SETENV} ${MAKE_ENV} jam -q -j4

do-test:
	cd ${WRKSRC} && prove

do-install:
	cd ${WRKSRC} && ${SETENV} ${MAKE_ENV} ${ALL_FAKE_FLAGS} jam install

.include <bsd.port.mk>
