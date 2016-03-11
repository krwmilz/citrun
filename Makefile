SUBDIR= bin instrument include lib viewer

test:
	prove

.include <bsd.subdir.mk>
