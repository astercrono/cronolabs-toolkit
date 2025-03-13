#!/usr/bin/env bash

function spinner() {
	pid=$1
	content="$2"
	is_test="$3"
	exit_code=0

	[ -z "$is_test" ] && is_test=0

	echo -ne "$content \r"

	while true; do
		if ! kill -0 $pid 2>/dev/null; then
			wait $pid
			exit_code=$?
			break
		fi

		content="$content."

		echo -ne "$content\r"
		sleep 1
	done

	if [ $is_test = 1 ]; then
		[ $exit_code = 0 ] && echo "$content "PASS
		[ $exit_code -ne 0 ] && echo "$content "FAIL
	else
		echo "$content "DONE
	fi

	return $exit_code
}
