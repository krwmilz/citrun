/*
 * if [[ ${1} = -* ]]; then
 * echo "usage: citrun_wrap <build cmd>"
 * exit 1
 * fi
 *
 * export PATH="`citrun_inst --print-share`:$PATH"
 * exec $@
 */
#include <limits.h>		/* PATH_MAX */
#include <stdlib.h>		/* setenv */
#include <unistd.h>		/* execvp */

int
main(int argc, char *argv[])
{
	char path[PATH_MAX];

	strlcpy(path, CITRUN_SHARE ":", PATH_MAX);
	strlcat(path, getenv("PATH"), PATH_MAX);

	if (setenv("PATH", path, 1))
		err(1, "setenv");

	argv[argc] = NULL;
	if (execvp(argv[1], argv + 1))
		err(1, "execv");
}
