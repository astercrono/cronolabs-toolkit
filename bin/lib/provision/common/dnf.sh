#!/usr/bin/env bash

function dnf_install() {
	sudo dnf install -y \
		cifs-utils \
		cockpit \
		curl \
		git \
		jq \
		less \
		neovim \
		openssh \
		openssl \
		python \
		sqlite \
		tmux \
		tree \
		vim \
		wget2
}
