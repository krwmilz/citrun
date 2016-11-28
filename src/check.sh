#
# Script that counts events in citrun.log files.
# Tries to be POSIX compatible.
#
err() {
	1>&2 echo $@
	exit 1
}

print_tty() {
	if [ -t 1 ]; then
		echo $@
	fi
}

args=`getopt o: $*`
if [ $? -ne 0 ]; then
	err "Usage: citrun-check [-o output file] [dir]"
fi
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

let log_files=0
while IFS= read -r line; do
	d="$line"
	print_tty -n .
	let log_files++

	let i=0
	while [ $i -lt $desc_len ]; do
		tmp=`grep -c "${GREP[$i]}" "$d"`
		let COUNT[$i]+=tmp
		let i++
	done

	let i=0
	typeset -i tmp
	while [ $i -lt $fine_len ]; do
		tmp=`awk "\\$0~/${FINE[$i]}/ { sum += \\$2 } END { print sum }" "$d"`
		if [ "$tmp" = "" ]; then
			let i++
			continue
		fi
		let FINE_COUNT[$i]+=tmp
		let i++
	done
done < $tmpfile
rm $tmpfile
print_tty "done"

if [ $log_files -eq 0 ]; then
	err "No log files found."
fi
print_tty

echo Summary:

let i=0
while [ $i -lt $desc_len ]; do
	if [ ${COUNT[$i]} -eq 0 ]; then
		let i++
		continue
	fi
	printf "%10i %s\n" ${COUNT[$i]} "${DESC[$i]}"
	let i++
done

echo
echo Totals:

let i=0
while [ $i -lt $fine_len ]; do
	if [ ${FINE_COUNT[$i]} -eq 0 ]; then
		let i++
		continue
	fi
	printf "%10i %s\n" ${FINE_COUNT[$i]} "${FINE[$i]}"
	let i++
done
