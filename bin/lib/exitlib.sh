#!/usr/bin/env bash

function ecc() {
	exit_code="$?"
	error_message="${1:-Error}"
	[ $exit_code != 0 ] && printf "\n** %s\n" "$error_message" && exit 1
}
export -f ecc

function fail() {
	error_message="${1:-Error}"
	printf "\n** %s\n" "$error_message" && exit 1
}
export -f fail
