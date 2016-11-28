#
# Script that counts events in citrun.log files.
# Tries to be POSIX compatible.
#
set -e
#set -u

err() {
	1>&2 echo $@
	exit 1
}

print_tty() {
	if [ -t 1 ]; then
		echo $@
	fi
}

range() {
	i=0
	while [ $i -lt $1 ]; do
		echo $i
		i=$((i + 1))
	done
}

args=`getopt o: $*`
set -- $args
while [ $# -ne 0 ]; do
	case "$1"
	in
		-o)
			# Redirect standard output to argument of -o.
			exec 1<&-; exec 1<>"$2"; shift; shift;;
		--)
			shift; break;;
	esac
done

# Avoid angering set -u by checking if $1 is even there first.
if [ -z "$1" ]; then
	# Directory not found after argument list.
	dir=`pwd`
else
	dir="$1"
fi
if [ ! -d $dir ]; then
	err "citrun-check: $dir: directory does not exist"
fi

GREP[0]="Found source file"
GREP[1]="Link detected"
GREP[2]="warning: "
GREP[3]="error: "
GREP[4]="Rewriting successful"
GREP[5]="Rewriting failed"
GREP[6]="Rewritten source compile successful"
GREP[7]="Rewritten source compile failed"

DESC[0]="Source files used as input"
DESC[1]="Application link commands"
DESC[2]="Rewrite parse warnings"
DESC[3]="Rewrite parse errors"
DESC[4]="Rewrite successes"
DESC[5]="Rewrite failures"
DESC[6]="Rewritten source compile successes"
DESC[7]="Rewritten source compile failures"
desc_len=${#DESC[@]}

FINE[0]="Lines of source code"
FINE[1]="Milliseconds spent rewriting source"
FINE[2]="Function definitions"
FINE[3]="If statements"
FINE[4]="For loops"
FINE[5]="While loops"
FINE[6]="Do while loops"
FINE[7]="Switch statements"
FINE[8]="Return statement values"
FINE[9]="Call expressions"
FINE[10]="Total statements"
FINE[11]="Binary operators"
FINE[12]="Errors rewriting source"
fine_len=${#FINE[@]}

print_tty -n Checking \'$dir\' .

tmpfile=`mktemp /tmp/citrun_check.XXXXXXXXXX`
trap "rm -f $tmpfile" 0
find $dir -name citrun.log > $tmpfile

log_files=0
while IFS= read -r line; do
	print_tty -n .
	log_files=1

	for i in `range $desc_len`; do
		# '|| true' because grep will exit non-zero if nothing is found.
		tmp=`grep -c "${GREP[$i]}" "$line" || true`
		COUNT[$i]=$((COUNT[$i] + tmp))
	done

	typeset -i tmp
	for i in `range $fine_len`; do
		tmp=`awk "\\$0~/${FINE[$i]}/ { sum += \\$2 } END { print sum }" "$line"`
		if [ "$tmp" = "" ]; then
			continue
		fi
		FINE_COUNT[$i]=$((FINE_COUNT[$i] + tmp))
	done
done < $tmpfile
rm $tmpfile
print_tty "done"

if [ $log_files -eq 0 ]; then
	err "No log files found."
fi
print_tty

echo Summary:

for i in `range $desc_len`; do
	if [ ${COUNT[$i]} -eq 0 ]; then
		continue
	fi
	printf "%10i %s\n" ${COUNT[$i]} "${DESC[$i]}"
done

echo
echo Totals:

for i in `range $fine_len`; do
	if [ ${FINE_COUNT[$i]} -eq 0 ]; then
		continue
	fi
	printf "%10i %s\n" ${FINE_COUNT[$i]} "${FINE[$i]}"
done
