#!/usr/bin/env bash

if [ -d "$APP_BASE/.venv" ]; then
	destroy_venv
	setup_venv
else
	fail "Virtual environment not found. Is program installed?"
fi
