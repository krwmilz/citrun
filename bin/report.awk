#
# Copyright (c) 2016, 2017 Kyle Milz <kyle@0x30.net>
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
$0~/>> citrun_inst/			{ summary[0] += 1 }
$0~/Found source file/			{ summary[1] += 1 }
$0~/Link detected/			{ summary[2] += 1 }
$0~/Rewritten source compile successfu/	{ summary[3] += 1 }
$0~/Rewritten source compile failed/	{ summary[4] += 1 }

$0~/Lines of source code/		{ totals[0] += $2 }
$0~/Milliseconds spent rewriting sourc/	{ totals[1] += $2 }
$0~/Function definitions/		{ totals[2] += $2 }
$0~/If statements/			{ totals[3] += $2 }
$0~/For loops/				{ totals[4] += $2 }
$0~/While loops/			{ totals[5] += $2 }
$0~/Do while loops/			{ totals[6] += $2 }
$0~/Switch statements/			{ totals[7] += $2 }
$0~/Return statement values/		{ totals[8] += $2 }
$0~/Call expressions/			{ totals[9] += $2 }
$0~/Total statements/			{ totals[10] += $2 }
$0~/Binary operators/			{ totals[11] += $2 }
$0~/Errors rewriting source/		{ totals[12] += $2 }

END {
	if (summary[0] == 0) {
		print "No signs of rewrite activity. Are any of the arguments log files?"
		exit 1
	}

	summary_desc[0] = "Rewrite tool runs"
	summary_desc[1] = "Source files used as input"
	summary_desc[2] = "Application link commands"
	summary_desc[3] = "Successful modified source compiles"
	summary_desc[4] = "Failed modified source compiles"

	print "Summary:"
	for (i = 0; i < 5; i++) {
		if (summary[i] == 0) continue
		printf "%10i %s\n", summary[i],	summary_desc[i]
	}

	totals_desc[0] = "Lines of source code"
	totals_desc[1] = "Milliseconds spent rewriting source"
	totals_desc[2] = "Function definitions"
	totals_desc[3] = "If statements"
	totals_desc[4] = "For loops"
	totals_desc[5] = "While loops"
	totals_desc[6] = "Do while loops"
	totals_desc[7] = "Switch statements"
	totals_desc[8] = "Return statement values"
	totals_desc[9] = "Call expressions"
	totals_desc[10] = "Total statements"
	totals_desc[11] = "Binary operators"
	totals_desc[12] = "Errors rewriting source"

	print ""
	print "Totals:"
	for (i = 0; i < 13; i++) {
		if (i != 0 && totals[i] == 0) continue
		printf "%10i %s\n", totals[i],	totals_desc[i]
	}
}
