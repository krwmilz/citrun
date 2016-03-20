SUBDIR= instrument lib viewer/glyphy viewer

test: all
	prove

.include <bsd.subdir.mk>
