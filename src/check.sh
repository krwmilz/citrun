#
# Copyright (c) 2016 Kyle Milz <kyle@0x30.net>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#
# Counts events in citrun.log files.
#
set -eu

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

dirs=$@
if [ -z $dirs ]; then
	dirs="."
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

print_tty -n "Checking '$dirs' ."

log_files=0
OIFS="$IFS"
IFS='
'
for line in `find $dirs -name citrun.log`; do
	print_tty -n .
	log_files=$((log_files + 1))

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
done
export IFS="$OIFS"
print_tty "done"
print_tty

echo Summary:

if [ $log_files -eq 0 ]; then
	printf "%10i %s\n" $log_files "citrun.log files processed"
	exit 0
fi

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
