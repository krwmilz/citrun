
if [[ ${1} = -* ]]; then
	echo "usage: citrun_wrap <build cmd>"
	exit 1
fi

export PATH="%CITRUN_SHARE%:$PATH"
exec $@
