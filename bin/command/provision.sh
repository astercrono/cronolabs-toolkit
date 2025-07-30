#!/usr/bin/env bash

# Usage: clt provision <target>

if [[ -z "$APP_USER_DIR" || "$APP_USER_DIR" == "0" ]]; then
	fail "User directory not set. Either set USER_DIR in config or pass -u <path> to program."
fi

export PRV_TARGET_HOSTNAME=""
export PRV_PROVISION_DIR="${APP_USER_DIR}/provision"
export PRV_HOST_FILE="$PRV_PROVISION_DIR/hosts.yaml"
export PRV_TEMPLATES_DIR="$PRV_PROVISION_DIR/templates"
export PRV_PROVISION_VARS=""
export PRV_TARGET_USER="$USER"

function validate_target() {
	[ -z "$1" ] && return 1
	is_valid=$(yq "has(\"$1\")" "$PRV_HOST_FILE")
	if [[ "$is_valid" == "true" ]]; then
		return 0
	else
		return 1
	fi
}
export -f validate_target

function ping_check() {
	ping -c 3 -W 2 "$PRV_TARGET_HOSTNAME" &>/dev/null &
	spinner $! "Pinging $PRV_TARGET_HOSTNAME"
	ecc "Unable to reach remote: $PRV_TARGET_HOSTNAME"
}

function provision_vars() {
	local vars=""
	local var_name var_value

	for var_name in $(printenv | grep "^APP_SEC_*" | cut -d '=' -f1); do
		var_value="${!var_name}"
		vars+="$(printf " export %q" "$var_name='$var_value'")"
	done

	echo $vars
}

function provision() {
	if [[ "$(yq "not (has(\"$PRV_TARGET.templates\")) or .$PRV_TARGET.templates | length == 0")" == "true" ]]; then
		echo "No templates to process"
		return 0
	fi

	pushd . &>/dev/null
	cd "$PRV_TEMPLATES_DIR"

	while IFS= read -r template_path; do
		[ ! -f "$template_path.sh" ] && fail "Template $template_path not found. Aborting!"

		echo ""
		echo "> Running $template_path"
		echo ""
		echo "[Provisioning $PRV_TARGET @ $PRV_TARGET_HOSTNAME]"
		echo ""

		case "$PRV_TARGET_HOSTNAME" in
		localhost)
			(
				eval "$PRV_PROVISION_VARS"
				"$template_path.sh"
			)
			;;
		*)
			ssh -o StrictHostKeyChecking=accept-new "$PRV_TARGET_USER"@"$PRV_TARGET_HOSTNAME" "$PRV_PROVISION_VARS && bash -s" <"$template_path.sh"
			;;
		esac

		[[ "$?" != "0" ]] && echo "Error running template. Aborting." && exit 1
	done < <(yq ".$PRV_TARGET.templates | .[]" "$PRV_HOST_FILE")

	popd &>/dev/null

}

function is_active() {
	if ping -c 1 -W 2 "$1" &>/dev/null; then
		echo "Yes"
	else
		echo "No"
	fi
}

function list_targets() {
	echo "File: $PRV_HOST_FILE"
	echo "--------------------------------------------------"

	previous_target=""
	while IFS= read target; do
		target_description=$(yq ".$target.description" "$PRV_HOST_FILE")
		target_hostname=$(yq ".$target.hostname" "$PRV_HOST_FILE")
		target_type=$(yq ".$target.type" "$PRV_HOST_FILE")
		target_parent=$(yq ".$target.parent" "$PRV_HOST_FILE")

		[[ "$target_parent" != "null" ]] && continue
		[ -n "$previous_target" ] && echo "--------------------------------------------------"

		printf "%-6s %s\n" "Name:" "$target"
		printf "%-6s %s\n" "Desc:" "$target_description"
		printf "%-6s %s\n" "Host:" "$target_hostname"
		printf "%-6s %s\n" "Type:" "$target_type"
		printf "%-6s %s\n" "Active:" "$(is_active $target_hostname)"

		while IFS= read sub_target; do
			echo ""

			sub_target_description=$(yq ".$sub_target.description" "$PRV_HOST_FILE")
			sub_target_hostname=$(yq ".$sub_target.hostname" "$PRV_HOST_FILE")
			sub_target_type=$(yq ".$sub_target.type" "$PRV_HOST_FILE")
			sub_target_parent=$(yq ".$sub_target.parent" "$PRV_HOST_FILE")

			printf "    > %-15s %s\n" "Name:" "$sub_target"
			printf "      %-15s %s\n" "Description:" "$sub_target_description"
			printf "      %-15s %s\n" "Hostname:" "$sub_target_hostname"
			printf "      %-15s %s\n" "Type:" "$sub_target_type"
			printf "      %-15s %s\n" "Active:" "$(is_active $sub_target_hostname)"
		done < <(yq "to_entries[] | select(.value.parent == \"$target\") | .key" "$PRV_HOST_FILE")

		previous_target="$target"
	done < <(yq "keys | to_entries | .[] | .value" "$PRV_HOST_FILE")
}

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
	if [[ "$2" == "--table" ]]; then
		pyrun "command.list_provision_hosts"
	else
		list_targets
	fi
	exit 0
	;;
info) ;;
esac

while getopts ":h:" opt; do
	case $opt in
	h)
		PRV_TARGET_HOSTNAME="${OPTARG}"
		;;
	*)
		clt usage provision
		fail "Unknown argument: $opt"
		;;
	esac
done
shift "$((OPTIND - 1))"

[ -z "$PRV_HOST_FILE" ] && echo "**Missing required hosts file" && echo "" && clt usage provision && exit 1
[ ! -f "$PRV_HOST_FILE" ] && fail "Invalid hosts file path"
yq e 'true' "$PRV_HOST_FILE" &>/dev/null || fail "Invalid host file. Not a YAML file."

[ -z "$PRV_TEMPLATES_DIR" ] && echo "**Missing required templates dir" && echo "" && clt usage provision && exit 1
[ ! -d "$PRV_TEMPLATES_DIR" ] && fail "Invalid templates dir"

export PRV_TARGET="$1"

[ -z "$PRV_TARGET" ] && fail "Missing required argument: <target>"

validate_target "$PRV_TARGET"
ecc "Invalid target. Does $PRV_TARGET exist in $PRV_HOST_FILE?"

shift

if [ -z "$PRV_TARGET_HOSTNAME" ]; then
	export PRV_TARGET_HOSTNAME=$(yq ".$PRV_TARGET.hostname" "$PRV_HOST_FILE")
fi

target_username=$(yq ".$PRV_TARGET.username" "$PRV_HOST_FILE")
[[ "$target_username" != "null" ]] && export PRV_TARGET_USER="$target_username"

load_secrets
ping_check

export PRV_PROVISION_VARS="$(provision_vars)"

provision
