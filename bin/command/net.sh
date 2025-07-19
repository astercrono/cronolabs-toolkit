#!/usr/bin/env bash

subcommand="$1"
show_process=false
filter_listening=true

shift

function list_active_ports() {
	cmd=""

	while getopts "pa" opt; do
		case "${opt}" in
		p) show_process=true ;;
		a) filter_listening=false ;;
		esac
	done
	shift $((OPTIND - 1))

	if [ $show_process = true ]; then
		cmd="lsof -i -P -n"
	else
		cmd="netstat -tuln"
	fi

	[ $filter_listening = true ] && cmd="$cmd | grep LISTEN"

	$cmd
}

case "$subcommand" in
stat) list_active_ports $@ ;;
*) fail "Invalid net command: $subcommand" ;;
esac
