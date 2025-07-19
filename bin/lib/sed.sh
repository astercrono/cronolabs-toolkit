#!/usr/bin/env bash

function qsed() {
	if command -v gsed >/dev/null; then
		gsed $@
	else
		sed $@
	fi
}
export -f qsed

function qsed_varsub() {
	var_name="$1"
	var_value="$2"
	filename="$3"
	qsed -i "s|{$var_name}|$var_value|g" $filename
}
export -f qsed_varsub

function qsed_sub() {
	pattern="$1"
	replacement="$2"
	filename="$3"
	qsed -i "s|$pattern|$replacement|g" $filename
}
export -f qsed_sub
