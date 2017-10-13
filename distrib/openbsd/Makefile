# $OpenBSD$

COMMENT =		see your code run

DISTNAME =		citrun-9999
CATEGORIES =		devel

HOMEPAGE =		http://cit.run

# BSD
PERMIT_PACKAGE_CDROM =	Yes

MASTER_SITES =		${HOMEPAGE}/

WANTLIB +=		GL GLU GLEW glfw c freetype m pthread z

# -std=c++11
MODULES =		gcc4
MODGCC4_ARCHS =		*
MODGCC4_LANGS =		c++

LIB_DEPENDS =		graphics/glew \
			graphics/glfw

BUILD_DEPENDS =		devel/jam \
			devel/llvm

TEST_DEPENDS =		devel/p5-Inline \
			devel/p5-Modern-Perl \
			devel/p5-Sys-Mmap \
			devel/p5-Test-Cmd \
			devel/p5-Test-Differences \
			devel/p5-Test-TrailingSpace \
			devel/p5-Test-WWW-Mechanize \
			graphics/p5-Imager \
			sysutils/p5-File-Which

CONFIGURE_STYLE =	simple

do-build:
	cd ${WRKSRC} && ${SETENV} ${MAKE_ENV} jam -q -j4

do-install:
	cd ${WRKSRC} && ${SETENV} ${MAKE_ENV} ${ALL_FAKE_FLAGS} jam install

.include <bsd.port.mk>
