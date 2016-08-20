#
# Make sure that citrun-wrap exits with the same code as the native build.
#
echo 1..1

src/citrun-wrap ls asdfasdfsaf 2> /dev/null

[ $? -eq 1 ] && echo ok 1 - return code
