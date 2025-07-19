#!/usr/bin/env bash

subcommand="$1"
shift

case "$subcommand" in
cleanup) temp_cleanup ;;
location) temp_location ;;
list) temp_list ;;
tree) temp_tree ;;
*)
	echo "Invalid command: $subcommand"
	exit 1
	;;
esac
