#!/usr/bin/env bash

# TODO: Look into tracking command history and enabling the up/down arrows on input

function breakpoint() {
	saved_exit_code="$?"
	echo "===== DEBUGGING ON ====="

	cmd=""
	while [[ "$cmd" != "c" ]]; do
		read -ep ">>> " cmd
		case "$cmd" in
		c) ;;
		q) exit 1 ;;
		*) eval "$cmd" ;;
		esac
	done

	echo "===== DEBUGGING OFF ====="
	return $saved_exit_code
}
export -f breakpoint
