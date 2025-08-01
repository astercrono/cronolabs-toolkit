#1/usr/bin/env bash

export PRV_PROVISION_DIR="${APP_USER_DIR}/provision"
export PRV_HOST_FILE="$PRV_PROVISION_DIR/hosts.yaml"
export PRV_TEMPLATES_DIR="$PRV_PROVISION_DIR/templates"
export PRV_PROVISION_VARS=""
export PRV_TARGET_USER="$USER"

function prv_validate_target() {
	[ -z "$1" ] && return 1
	is_valid=$(yq "has(\"$1\")" "$PRV_HOST_FILE")
	if [[ "$is_valid" == "true" ]]; then
		return 0
	else
		return 1
	fi
}
export -f prv_validate_target

function prv_ping_check() {
	ping -c 3 -W 2 "$PRV_TARGET_HOSTNAME" &>/dev/null &
	spinner $! "Pinging $PRV_TARGET_HOSTNAME"
	ecc "Unable to reach remote: $PRV_TARGET_HOSTNAME"
}
export -f prv_ping_check

function provision_vars() {
	local vars=""
	local var_name var_value

	for var_name in $(printenv | grep "^APP_SEC_*" | cut -d '=' -f1); do
		var_value="${!var_name}"
		vars+="$(printf " export %q" "$var_name=$var_value")"
	done

	echo $vars
}
export -f provision_vars

function provision() {
	if [[ "$(yq "not (has(\"$PRV_TARGET.templates\")) or .$PRV_TARGET.templates | length == 0")" == "true" ]]; then
		echo "No templates to process"
		return 0
	fi

	pushd . &>/dev/null
	cd "$PRV_TEMPLATES_DIR"

	echo ""
	echo "[Provisioning $PRV_TARGET @ $PRV_TARGET_HOSTNAME]"

	while IFS= read -r template_path; do
		[ ! -f "$template_path.sh" ] && fail "Template $template_path not found. Aborting!"

		echo ""
		echo "> Running $template_path"
		echo ""

		case "$PRV_TARGET_HOSTNAME" in
		localhost)
			(
				eval "$PRV_PROVISION_VARS"
				"$template_path.sh"
			)
			;;
		*)
			ssh -o StrictHostKeyChecking=no "$PRV_TARGET_USER"@"$PRV_TARGET_HOSTNAME" "$PRV_PROVISION_VARS && bash -s" <"$template_path.sh"
			;;
		esac

		[[ "$?" != "0" ]] && echo "Error running template. Aborting." && exit 1
	done < <(yq ".$PRV_TARGET.templates | .[]" "$PRV_HOST_FILE")

	popd &>/dev/null
}
export -f provision

function host_is_up() {
	if ping -c 1 -W 2 "$1" &>/dev/null; then
		echo "Yes"
	else
		echo "No"
	fi
}
export -f host_is_up

function prv_list_targets() {
	while [ $# -gt 0 ]; do
		case "$1" in
		--ping)
			ping_mode=true
			shift
			;;
		esac
		shift
	done

	echo "Host File: $PRV_HOST_FILE"
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
		[[ $ping_mode == true ]] && printf "%-6s %s\n" "Active:" "$(host_is_up $target_hostname)"

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
			[[ $ping_mode == true ]] && printf "      %-15s %s\n" "Active:" "$(host_is_up $sub_target_hostname)"
		done < <(yq "to_entries[] | select(.value.parent == \"$target\") | .key" "$PRV_HOST_FILE")

		previous_target="$target"
	done < <(yq "keys | to_entries | .[] | .value" "$PRV_HOST_FILE")
}
export -f prv_list_targets
