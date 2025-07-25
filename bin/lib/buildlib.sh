#!/usr/bin/env bash

function build() {
	uv pip install -e .
	ecc
	pre-commit install
	ecc
}
export -f build

function setup_venv() {
	uv sync
	ecc
}
export -f setup_venv

function destroy_venv() {
	echo "Removing virtual environment"
	rm -rf "$APP_BASE/.venv"
	ecc
}
export -f destroy_venv

function upgrade_lockfile() {
	uv lock --upgrade
}
export -f upgrade_lockfile
