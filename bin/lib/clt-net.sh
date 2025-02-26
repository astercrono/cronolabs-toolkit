#!/usr/bin/env bash

subcommands=("stat")
SUBCOMMAND="$1"
SHOW_PROCESS=false
FILTER_LISTENING=true

shift

if [[ ! " ${subcommands[@]} " =~ " $SUBCOMMAND" ]] || [ -z "$SUBCOMMAND" ]; then
	echo "Invalid net command: $SUBCOMMAND"
	exit 1
fi

while getopts "pa" opt; do
	case "${opt}" in
	p) SHOW_PROCESS=true ;;
	a) FILTER_LISTENING=false ;;
	esac
done
shift $((OPTIND - 1))

function list_active_ports() {
	cmd=""

	if [ $SHOW_PROCESS = true ]; then
		cmd="sudo lsof -i -P -n"
	else
		cmd="sudo netstat -tuln"
	fi

	[ $FILTER_LISTENING = true ] && cmd="$cmd | grep LISTEN"
	eval $cmd
}

case "$SUBCOMMAND" in
stat) list_active_ports $@ ;;
esac
