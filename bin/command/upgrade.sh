#!/usr/bin/env bash

if [ -d "$APP_BASE/.venv" ]; then
	destroy_venv
	upgrade_lockfile
	setup_venv
	build
else
	fail "Virtual environment not found. Is program installed?"
fi
