#!/usr/bin/env bash

subcommand="$1"
shift

if [ -z "$subcommand" ]; then
	if command -v bat >/dev/null; then
		bat -l bash $APP_DATA_CONFIG
	else
		cat $APP_DATA_CONFIG
	fi
	exit 0
fi

case "$subcommand" in
get)
	get_config "$1"
	;;
set)
	set_config "$1" "$2"
	;;
reset)
	reset_config
	;;
ls)
	ls $APP_DATA
	;;
location)
	echo $APP_DATA
	;;
*)
	echo "Invalid command: $subcommand"
	exit 1
	;;
esac

exit 0
