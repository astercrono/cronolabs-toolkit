#!/usr/bin/env bash

export PATH_EXPORT='export PATH=$PATH'":$APP_BIN"
cd $APP_BASE

function install_path() {
	RC_FILE=""
	echo $SHELL | grep zsh >/dev/null 2>&1
	if [ $? == 0 ]; then
		RC_FILE="$HOME/.zshrc"
	fi
	echo $SHELL | grep bash
	if [ $? == 0 ]; then
		RC_FILE="$HOME/.bashrc"
	fi
	if [ -z "${RC_FILE}" ]; then
		fail "Unable to locate zshrc or bashrc"
	fi
	if ! grep -qF "$PATH_EXPORT" "$RC_FILE"; then
		echo $PATH_EXPORT >>$RC_FILE
	fi
}
export -f install_path

function run_install() {
	cd "$APP_BASE"

	echo "> Looking for Preinstallable Dependencies"
	preinstall_deps
	echo ""

	echo "> Syncing Environment"
	setup_venv
	ecc
	echo ""

	echo "> Building Project"
	build
	echo ""

	install_path
	ecc

	echo ""
	echo "Installation complete. Reload your shell."
	echo ""

	cat $APP_RESOURCE/coffee.txt

	echo ""
	echo "Enjoy"
	ecc
	exit 0
}
export -f run_install

function validate_target() {
	[ -z "$1" ] && return 1
	is_valid=$(yq "has(\"$1\")" "$APPC_PROVISION_CONFIG")
	if [[ "$is_valid" == "true" ]]; then
		return 0
	else
		return 1
	fi
}
export -f validate_target

function install() {
	provision="$1"
	remote="$2"
	branch="$3"

	echo "provision: $provision, remote: $remote, branch: $branch"

	case "$PROVISION" in
	true)
		echo "Provisioning"
		echo "Installing"
		;;
	false)
		echo "Installing"
		;;
	esac
}

target="$1"
branch=$(git rev-parse --abbrev-ref HEAD)
ecc "Unable to determine branch"

[ -z "$target" ] && fail "Missing required argument: <target>"

remote_hostname=$(yq ".$target.hostname" "$APPC_PROVISION_CONFIG")

validate_target "$target"
ecc "Invalid target. Does $target exist in $APPC_PROVISION_CONFIG?"

shift

provition=false
while getopts ":p" opt; do
	case "$opt" in
	p)
		provision=true
		;;
	esac
done

echo ""

case "$remote_hostname" in
localhost)
	echo "Installing locally"
	;;
*)
	echo "Installing to $remote_hostname"
	;;
esac

if [[ "$provision" == true ]]; then
	echo "provision"
	ecc "Error provisionioning"
fi
