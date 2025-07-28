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

function install_local() {
	provision="$1"
	remote="$2"
	branch="$3"

	if [[ "$provision" == true ]]; then
		echo "provision"
		ecc "Error provisionioning"
	fi

	echo "provision: $provision, remote: $remote, branch: $branch"
}

function install_remote() {
	provision="$1"
	target="$2"
	branch="$3"

	if [[ "$provision" == true ]]; then
		echo "provision"
		ecc "Error provisionioning"
	fi
}

run_install
