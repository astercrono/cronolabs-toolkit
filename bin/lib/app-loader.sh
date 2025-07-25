#!/usr/bin/env bash

export APP_OS="$(uname -s)"
export APP_DATA="$HOME/.local/share/$APP_NAME"
export APP_DATA_CONFIG="$APP_DATA/config"

export dependencies=("uv" "pre-commit" "yq")

source "$APP_BIN/lib/debug.sh"
source "$APP_BIN/lib/spinner.sh"
source "$APP_BIN/lib/exitlib.sh"
source "$APP_BIN/lib/pythonlib.sh"
source "$APP_BIN/lib/buildlib.sh"
source "$APP_BIN/lib/config.sh"
source "$APP_BIN/lib/sed.sh"
source "$APP_BIN/lib/temp.sh"
source "$APP_BIN/lib/core.sh"

command="$1"
shift

function check_deps() {
	silent="$1"
	success=0

	[[ "$silent" != "1" ]] && echo "Checking dependencies:"

	for dep in "${dependencies[@]}"; do
		if command -v $dep &>/dev/null; then
			[[ "$silent" != "1" ]] && printf "    %-20s %-10s\n" "$dep" "FOUND"
		else
			[[ "$silent" != "1" ]] && printf "    %-20s %-10s\n" "$dep" "NOT FOUND"
			success=1
		fi
	done

	[ $success -gt 0 ] && fail "Missing dependencies"
}
export -f check_deps

function preinstall_deps() {
	# Mac needs GNU Sed
	if uname | grep -i -q "darwin" && ! command -v gsed &>/dev/null && command -v brew &>/dev/null; then
		brew install gnu-sed
		ecc
	fi
}
export -f preinstall_deps

function print_timestamp() {
	case "$APP_OS" in
	"Darwin")
		date -r "$1"
		;;
	"Linux")
		date -d "@$1"
		;;
	*)
		fail "Unsupported platform"
		;;
	esac
}
export -f print_timestamp

function fopen() {
	case "$APP_OS" in
	"Darwin")
		open "$1"
		;;
	"Linux")
		xdg-open "$1"
		;;
	*)
		fail "Unsupported platform"
		;;
	esac
}
export -f fopen

function touch_timestamp() {
	if uname | grep -i -q "darwin"; then
		date -r "$1" +"%Y%m%d%H%M.%S"
	else
		date -d "@$1" +"%Y%m%d%H%M.%S"
	fi
}
export -f touch_timestamp

function command_list {
	yq -r '.commands | to_entries | .[] | .key' "$APP_COMMANDS_FILE" | sort
}

function list() {
	printf "Supported commands: \n"
	for key in $(command_list); do
		desc=$(yq ".commands.$key.description" "$APP_COMMANDS_FILE")
		printf "    %-15s %-40s\n" "$key" "$desc"
	done
	echo ""
	echo "Run $APP_NAME usage <command> for details"
}

function run_cmd() {
	[[ "$command" == "install" ]] && check_deps
	check_deps 1

	cd "$APP_BASE"
	cmd=$(yq ".commands.$command | key" $APP_COMMANDS_FILE)

	case "$cmd" in
	usage)
		usage_cmd="$1"
		if [[ "$usage_cmd" == "" ]]; then
			for key in $(command_list); do
				desc=$(yq ".commands.$key.description" "$APP_COMMANDS_FILE")
				printf "    %-15s %-40s\n" "$key" "$desc"

				usage_msg=$(yq ".commands.$key.usage" "$APP_COMMANDS_FILE")
				[[ "$usage_msg" != "null" ]] && printf "    %-15s %-40s\n" "" "Usage: $APP_NAME $usage_msg"
			done
		else
			if ! yq -e ".commands.$usage_cmd" $APP_COMMANDS_FILE >/dev/null 2>&1; then
				echo "Unknown command: $usage_cmd" && echo "Usage: $APP_NAME usage [command]" && echo "" && list && exit 1
			fi

			desc=$(yq ".commands.$usage_cmd.description" "$APP_COMMANDS_FILE")
			usage_msg=$(yq ".commands.$usage_cmd.usage" $APP_COMMANDS_FILE)

			[[ "$usage_msg" == "null" ]] && usage_msg=""

			printf "%-15s %-40s\n" "Command:" "$usage_cmd"
			printf "%-15s %-40s\n" "Description:" "$desc"
			printf "%-15s %-40s\n" "Usage:" "$APP_NAME $usage_cmd $usage_msg"
		fi
		;;
	list) list ;;
	*)
		if [ -f "bin/command/$cmd.sh" ]; then
			bash bin/command/$cmd.sh $@
		elif module_exists "command.$cmd"; then
			pyrun "command.$cmd" $@
		else
			echo "Unable to locate command as script or Python module"
			exit 1
		fi
		;;
	esac
}

function indent_output() {
	"$@" 2>&1 | sed 's/^/    /'
}
export -f indent_output

function handle_sigint() {
	echo "Exiting..."
	exit 1
}
trap handle_sigint SIGINT

if [ -z "$command" ]; then
	echo "Missing command" && list && exit 1
elif ! yq -e ".commands.$command" $APP_COMMANDS_FILE >/dev/null 2>&1; then
	echo "Unknown command: $command" && list && exit 1
fi

ensure_data_dir
clean_user_config
match_config_to_template
load_user_config
ensure_temp
check_data_dir

run_cmd $@
