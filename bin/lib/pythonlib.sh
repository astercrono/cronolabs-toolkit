#!/usr/bin/env bash

function module_exists() {
	local module_name="$APP_NAME.$1"
	uv run - <<EOF
import importlib.util
module_name = '$module_name'
spec = importlib.util.find_spec(module_name)
if spec is not None:
	exit(0)
else:
	exit(1)
EOF
	return $?
}
export -f module_exists

function pyrun() {
	uv run python -m "$APP_NAME.$1"
}
export -f pyrun
