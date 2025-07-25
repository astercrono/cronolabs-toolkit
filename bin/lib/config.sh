#!/usr/bin/env bash

function sub_in_config_vars() {
	qsed_varsub "APP_DATA" "$APP_DATA" "$APP_DATA_CONFIG"
	qsed_varsub "APP_BASE" "$APP_BASE" "$APP_DATA_CONFIG"

	cores="$(corecount)"
	if [[ -n "$cores" && "$cores" =~ ^-?[0-9]+$ ]]; then
		qsed_varsub "TOTAL_CORE_COUNT" "$cores" "$APP_DATA_CONFIG"
	else
		qsed_varsub "TOTAL_CORE_COUNT" "1" "$APP_DATA_CONFIG"
	fi

}
export -f sub_in_config_vars

function ensure_temp() {
	if [ ! -d "$APPC_TEMP" ]; then
		temp_path="$(mktemp -d $APP_DATA/temp.XXXXXX)"
		ecc "Failed to create temp directory"
		qsed_varsub "TEMP_PATH" "$temp_path" "$APP_DATA_CONFIG"
		load_user_config
	fi
}
export -f ensure_temp

function ensure_data_dir() {
	mkdir -p $APP_DATA
	chmod 700 $APP_DATA

	[ ! -d "$APP_DATA" ] && echo "Does not exist!"

	if [ ! -f "$APP_DATA_CONFIG" ]; then
		cat "$APP_RESOURCE/config" >"$APP_DATA_CONFIG"
		sub_in_config_vars
	fi
}
export -f ensure_data_dir

function load_user_config() {
	while IFS='=' read -r key value; do
		if grep -q "$key=" $APP_RESOURCE/config; then
			val=$(echo "$value" | tr -d '[:space:]')
			export "APPC_${key}=${val}"
		fi
	done <$APP_DATA_CONFIG
}
export -f load_user_config

function clean_user_config() {
	# Remove newlines
	qsed -i '' '/^[[:space:]]*$/d' $APP_DATA_CONFIG

	# Remove lines that do not match key=value format
	qsed -i '/^[A-Za-z_][A-Za-z0-9_]*=.*/!d' $APP_DATA_CONFIG
}
export -f clean_user_config

function match_config_to_template() {
	# Add missing configs from template to user config
	while IFS='=' read -r key value; do
		if ! grep -q "$key=" $APP_DATA_CONFIG; then
			echo "$key=$value" >>$APP_DATA_CONFIG
			sub_in_config_vars
		fi
	done <$APP_RESOURCE/config

	# Remove entries from user config that are not in template
	unknown_keys=()
	while IFS='=' read -r key value; do
		if ! grep -q "$key=" $APP_RESOURCE/config; then
			unknown_keys+=("$key=")
		fi
	done <$APP_DATA_CONFIG

	for k in "${unknown_keys[@]}"; do
		qsed -i "/$k/d" $APP_DATA_CONFIG
	done
}
export -f match_config_to_template

function reset_config() {
	[ -f "$APP_DATA_CONFIG" ] && rm "$APP_DATA_CONFIG"
	ensure_data_dir
	match_config_to_template
}
export -f reset_config

function check_data_dir() {
	# Do the directories exist?
	if [[ ! -d "$APP_DATA" ]]; then
		fail "[ERROR] $APPC_DATA is not a directory"
	fi

	if [[ ! -d "$APPC_TEMP" ]]; then
		fail "[ERROR] $APPC_TEMP is not a directory"
	fi

	# Confirm they are not symlinks
	if [[ -L "$APP_DATA" ]]; then
		fail "[ERROR] $APP_DATA has been symlinked. This is now allowed!"
	fi

	if [[ -L "$APPC_TEMP" ]]; then
		fail "[ERROR] $APPC_TEMP has been symlinked. This is now allowed!"
	fi
}
export -f check_data_dir

function set_config() {
	config_name="${1^^}"
	[ -z "$config_name" ] && echo "Missing NAME" && exit 1

	new_config_value="$2"
	[ -z "$config_name" ] && echo "Missing VALUE" && exit 1

	var_name="APPC_${config_name}"
	[ -z "${!var_name}" ] && echo "Unknown config: ${config_name}" && exit 1

	original_var_value="${!var_name}"
	qsed_sub "$config_name=$original_var_value" "$config_name=$new_config_value" $APP_DATA_CONFIG
	load_user_config
}
export -f set_config

function get_config() {
	config_name="${1^^}"
	[ -z "$config_name" ] && echo "Missing NAME" && exit 1

	var_name="APPC_${config_name}"
	[ -z "${!var_name}" ] && echo "Unknown config: ${config_name}" && exit 1

	echo "${!var_name}"
}
export -f get_config
