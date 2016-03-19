SUBDIR= glyphy instrument lib viewer

test: all
	prove

.include <bsd.subdir.mk>
