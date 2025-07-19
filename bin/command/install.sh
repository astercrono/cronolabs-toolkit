#!/usr/bin/env bash

PATH_EXPORT='export PATH=$PATH'":$APP_BIN"
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

function handle_sigint() {
	echo "Exiting..."
	exit 1
}
trap handle_sigint SIGINT

echo "> Checking Dependencies"
check_deps
echo ""

echo "> Looking for Preinstallable Dependencies"
preinstall_deps
echo ""

echo "> Syncing Environment"
setup_venv
echo ""

echo "> Building Project"
build
echo ""

install_path

echo ""
echo "Installation complete. Reload your shell."
echo ""

cat $APP_RESOURCE/coffee.txt

echo ""
echo "Enjoy"
