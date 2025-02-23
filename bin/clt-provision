#!/usr/bin/env bash

subcommands=("fedora")

SUBCOMMAND="$1"
GROUP="all"
CATEGORY="all"

shift

if [[ ! " ${subcommands[@]} " =~ " $SUBCOMMAND" ]] || [ -z "$SUBCOMMAND" ]; then
	echo "Invalid system type: $SUBCOMMAND"
	exit 1
fi

while getopts "g:c:" opt; do
	case "${opt}" in
	g) GROUP="${OPTARG}" ;;
	c) CATEGORY="${OPTARG}" ;;
	esac
done
shift $((OPTIND - 1))

sudo -v

function install_from_file_single() {
	filename="$1"
	shift
	while IFS= read -r line; do
		IFS=':'
		read -ra split <<<"$line"

		install_group=${split[0]}
		install_category=${split[1]}
		install_package=${split[2]}

		if [[ "$install_group" == "all" ]] || [[ "$GROUP" == "$install_group" ]]; then
			if [[ "$install_category" == "all" ]] || [[ "$CATEGORY" == "$install_category" ]]; then
				eval "$@ $install_package"
			fi
		fi
	done <"$CLT_BIN/$filename"
}

function install_from_file_batch() {
	filename="$1"
	shift

	install_batch=()
	while IFS= read -r line; do
		IFS=':'
		read -ra split <<<"$line"

		install_group=${split[0]}
		install_category=${split[1]}
		install_package=${split[2]}

		if [[ "$install_group" == "all" ]] || [[ "$GROUP" == "$install_group" ]]; then
			if [[ "$install_category" == "all" ]] || [[ "$CATEGORY" == "$install_category" ]]; then
				install_batch+=($install_package)
			fi
		fi
	done <"$CLT_BIN/$filename"

	eval "$@ ${install_batch[@]}"
}

function install_packages() {
	case $SUBCOMMAND in
	fedora)
		sudo dnf update -y

		if [[ "$GROUP" == "workstation" ]]; then
			sudo dnf copr -y enable wezfurlong/wezterm-nightly
			sudo dnf update -y
		fi

		install_from_file_batch "dnf-list.txt" "sudo dnf install -y"

		if [[ "$GROUP" == "workstation" ]]; then
			flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
			install_from_file_single "flatpak-list.txt" "flatpak install -y"
		fi

		;;
	debian)
		echo "Unsupported system type"
		;;
	*)
		echo "Unknown system type"
		;;
	esac
}

function config_nvim() {
	echo "installing Neovim config"

	config_dir="$HOME/.config"
	nvim_dir="$config_dir/nvim"
	mkdir -p $config_dir

	if [ -L "$nvim_dir" ]; then
		rm "$nvim_dir"
	elif [ -d "$nvim_dir" ]; then
		mv $nvim_dir "$nvim_dir-backup"
	fi

	ln -s $CLT_BASE/resource/nvim $nvim_dir
}

function config_wezterm() {
	wez_config="$HOME/.wezterm.lua"
	echo "installing wezterm config"

	if [ -L "$wez_config" ]; then
		rm "$wez_config"
	elif [ -f "$wez_config" ]; then
		mv $wez_config "$wez_config-backup"
	fi

	ln -s $CLT_BASE/resource/wezterm/.wezterm.lua $wez_config
}

install_packages

if [[ "$GROUP" == "workstation" ]]; then
	config_nvim
	config_wezterm
fi
