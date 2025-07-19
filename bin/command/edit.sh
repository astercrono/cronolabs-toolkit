#!/usr/bin/env bash
[ -z "$EDITOR" ] && fail "Editor not defined"

cd $APP_BASE
uv run $EDITOR .
