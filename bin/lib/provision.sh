#!/usr/bin/env bash

# provision lib

function provision() {
	target="$1"

	[ -z "$target" ] && fail "Missing required argument: <target>"
}
