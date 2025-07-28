#!/usr/bin/env bash

function validate_bws() {
	[ ! command -v bws ] &>/dev/null && fail "Missing required program: bws (bitwarden secrets manager)"
}
export -f validate_bws

function bws_auth() {
	if [[ "$APPC_BWS_ACCESS_TOKEN" == "0" ]]; then
		read -p "Enter Bitwarden Access Token: " bws_access_token
		set_config "BWS_ACCESS_TOKEN" "$bws_access_token"
		ecc
	fi

	if ! BWS_ACCESS_TOKEN="$APPC_BWS_ACCESS_TOKEN" bws secret list &>/dev/null; then
		printf "** BWS_ACCESS_TOKEN either not set or invalid. \n** Set environment variable or use clt config set bws_access_token <token>\n"
		exit 1
	fi
}
export -f bws_auth

function bws_load_secrets() {
	validate_bws
	bws_auth

	while IFS='=' read -r key value; do
		clean_key=$(echo "$key" | tr '.' '_' | tr '[:lower:]' '[:upper:]')
		export "APP_SEC_$clean_key"="$value"
	done < <(cbws secret list | jq -r '.[] | "\(.key)=\(.value)"')
}
export -f bws_load_secrets

function cbws() {
	validate_bws
	bws_auth
	BWS_ACCESS_TOKEN="$APPC_BWS_ACCESS_TOKEN" bws $@
	ecc
}
export -f cbws
