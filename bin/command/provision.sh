#!/usr/bin/env bash

# Usage: clt provision <target>

if [[ -z "$APP_USER_DIR" || "$APP_USER_DIR" == "0" ]]; then
	fail "User directory not set. Either set USER_DIR in config or pass -u <path> to program."
fi

function handle_exit() {
	[[ "$?" != "0" ]] && echo "Exiting..."
	exit $?
}
trap handle_exit EXIT

function handle_sigint() {
	echo "Exiting..."
	exit 1
}
trap handle_sigint SIGINT

[ -z "$PRV_PROVISION_DIR" ] && echo "**Missing required provision dir" && echo "" && clt usage provision && exit 1
[ ! -d "$PRV_PROVISION_DIR" ] && fail "Invalid provision dir"

case "$1" in
list)
	shift

	table_mode=false

	for arg in "$@"; do
		if [[ "$arg" == "--table" ]]; then
			table_mode=true
			break
		fi
	done

	case $table_mode in
	true)
		pyrun "command.list_provision_hosts" $@
		;;
	false)
		prv_list_targets $@
		;;
	esac

	exit 0
	;;
info)
	echo "Not implemented"
	exit 0
	;;
esac

[ -z "$PRV_HOST_FILE" ] && echo "**Missing required hosts file" && echo "" && clt usage provision && exit 1
[ ! -f "$PRV_HOST_FILE" ] && fail "Invalid hosts file path"
yq e 'true' "$PRV_HOST_FILE" &>/dev/null || fail "Invalid host file. Not a YAML file."

[ -z "$PRV_TEMPLATES_DIR" ] && echo "**Missing required templates dir" && echo "" && clt usage provision && exit 1
[ ! -d "$PRV_TEMPLATES_DIR" ] && fail "Invalid templates dir"

export PRV_TARGET="$1"
[ -z "$PRV_TARGET" ] && fail "Missing required argument: <target>"

prv_validate_target "$PRV_TARGET"
ecc "Invalid target. Does $PRV_TARGET exist in $PRV_HOST_FILE?"

shift

if [ -z "$PRV_TARGET_HOSTNAME" ]; then
	export PRV_TARGET_HOSTNAME=$(yq ".$PRV_TARGET.hostname" "$PRV_HOST_FILE")
fi

target_username=$(yq ".$PRV_TARGET.username" "$PRV_HOST_FILE")
[[ "$target_username" != "null" ]] && export PRV_TARGET_USER="$target_username"

load_secrets
prv_ping_check

export PRV_PROVISION_VARS="$(provision_vars)"

provision
