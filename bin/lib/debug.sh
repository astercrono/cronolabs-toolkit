#!/usr/bin/env bash

function breakpoint() {
	saved_exit_code="$?"
	echo "===== DEBUGGING ON ====="

	cmd=""
	while [[ "$cmd" != "c" ]]; do
		read -p ">>> " cmd
		case "$cmd" in
		c) ;;
		*) eval "$cmd" ;;
		esac
	done

	echo "===== DEBUGGING OFF ====="
	return $saved_exit_code
}
