#!/usr/bin/env bash

PATH_EXPORT='export PATH=$PATH'":$CLT_BIN"
EDIT_MODE=false

cd $CLT_BIN/..

while getopts ":e" opt; do
    case "${opt}" in
    e) EDIT_MODE=true ;;
    esac
done
shift $((OPTIND - 1))


function check_deps() {
    if ! command -v python3 &>/dev/null && ! command -v python &>/dev/null; then
        echo "Python is not installed. Please install Python to proceed."
        exit 1
    fi
}

function setup_venv() {
    if [ -d ".venv" ]; then
        echo "Virtualenv directory already exists."
    else
        echo "Virtualenv directory does not exist. Creating it now..."
        python3 -m venv .venv
    fi
    source .venv/bin/activate
}

function build() {
    if [ $EDIT_MODE = true ]; then
        pip install -e .
    else
        pip install .
    fi
}

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
        echo "Unable to locate zshrc or bashrc"
        exit 1
    fi
    if ! grep -qF "$PATH_EXPORT" "$RC_FILE"; then
        echo $PATH_EXPORT >>$RC_FILE
    fi
}

check_deps
setup_venv
build
install_path

echo ""
echo "Installation complete. Reload your shell."
echo ""

cat $CLT_BIN/coffee.txt

echo ""
echo "Enjoy"
