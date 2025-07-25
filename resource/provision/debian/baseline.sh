#!/usr/bin/env bash

touch /etc/apt/sources.list.d/debian-backports.list
echo "deb http://deb.debian.org/debian bookworm-backports main contrib non-free" | tee -a /etc/apt/sources.list.d/debian-backports.list

apt-get update -y
apt-get install -y cifs-utils cockpit curl less openssh-server openssl python3 sqlite3 tmux tree vim wget2
