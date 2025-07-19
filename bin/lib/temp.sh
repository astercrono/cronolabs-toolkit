#!/usr/bin/env bash

function temp_cleanup() {
	[ -d "$APPC_TEMP" ] && rm -r "$APPC_TEMP"
	ensure_temp
}
export -f temp_cleanup

function temp_location() {
	echo "$APPC_TEMP"
}
export -f temp_location

function temp_list() {
	find $APPC_TEMP -type f -exec echo {} \;
}
export -f temp_list

function temp_tree() {
	if command -v tree; then
		tree "$APPC_TEMP"
	else
		echo "Missing program: tree. Falling back to flat list."
		temp_list
	fi
}
export -f temp_tree
