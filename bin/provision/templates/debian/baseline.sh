#!/usr/bin/env bash

apt-get update -y
apt upgrade -y

backport_source_file="/etc/apt/sources.list.d/debian-backports.list"
if [ ! -f "$backport_source_file" ]; then
	touch "$backport_source_file"
	echo "deb http://deb.debian.org/debian bookworm-backports main contrib non-free" | tee -a "$backport_source_file"
fi

apt-get update -y
apt-get install -y cifs-utils cockpit curl less openssh-server openssl python3 sqlite3 tmux tree wget2 vim neovim

if command -v uv &>/dev/null; then
	uv self update
else
	curl -LsSf https://astral.sh/uv/install.sh | sh
fi
