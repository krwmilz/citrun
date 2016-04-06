#
# Regular cron jobs for the citrun package
#
0 4	* * *	root	[ -x /usr/bin/citrun_maintenance ] && /usr/bin/citrun_maintenance
