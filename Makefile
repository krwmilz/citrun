SUBDIR= instrument lib viewer wrap

test:
	prove

.include <bsd.subdir.mk>
