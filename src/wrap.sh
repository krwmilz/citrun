
if [[ ${1} = -* ]]; then
	echo "usage: citrun-wrap <build cmd>"
	exit 1
fi

export PATH="%CITRUN_SHARE%:$PATH"
exec $@