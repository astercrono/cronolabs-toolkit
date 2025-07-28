#!/usr/bin/env bash

export APP_OS="$(uname -s)"
export APP_DATA="$HOME/.local/share/$APP_NAME"
export APP_DATA_CONFIG="$APP_DATA/config"

export dependencies=("uv" "pre-commit" "yq" "jq")

source "$APP_BIN/lib/debug.sh"
source "$APP_BIN/lib/spinner.sh"
source "$APP_BIN/lib/exitlib.sh"
source "$APP_BIN/lib/pythonlib.sh"
source "$APP_BIN/lib/buildlib.sh"
source "$APP_BIN/lib/config.sh"
source "$APP_BIN/lib/sed.sh"
source "$APP_BIN/lib/temp.sh"
source "$APP_BIN/lib/core.sh"
source "$APP_BIN/lib/bwlib.sh"

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
	echo "$APP_COMMANDS" | yq -r '.commands | to_entries | .[] | .key' | sort
}

function list() {
	printf "Supported commands: \n"
	for key in $(command_list); do
		desc=$(echo "$APP_COMMANDS" | yq ".commands.$key.description")
		printf "    %-15s %-40s\n" "$key" "$desc"
	done
	echo ""
	echo "Run $APP_NAME usage <command> for details"
}

function run_cmd() {
	[[ "$command" == "install" ]] && check_deps
	check_deps 1

	cd "$APP_BASE"
	cmd=$(echo "$APP_COMMANDS" | yq ".commands.$command | key")

	case "$cmd" in
	usage)
		usage_cmd="$1"
		if [[ "$usage_cmd" == "" ]]; then
			for key in $(command_list); do
				desc=$(echo "$APP_COMMANDS" | yq ".commands.$key.description")
				printf "    %-15s %-40s\n" "$key" "$desc"

				usage_msg=$(yq ".commands.$key.usage" "$APP_COMMANDS_FILE")
				[[ "$usage_msg" != "null" ]] && printf "    %-15s %-40s\n" "" "Usage: $APP_NAME $usage_msg"
			done
		else
			if ! echo "$APP_COMMANDS" | yq -e ".commands.$usage_cmd" >/dev/null 2>&1; then
				echo "Unknown command: $usage_cmd" && echo "Usage: $APP_NAME usage [command]" && echo "" && list && exit 1
			fi

			desc=$(echo "$APP_COMMANDS" | yq ".commands.$usage_cmd.description")
			usage_msg=$(echo "$APP_COMMANDS" | yq ".commands.$usage_cmd.usage")

			[[ "$usage_msg" == "null" ]] && usage_msg=""

			printf "%-15s %-40s\n" "Command:" "$usage_cmd"
			printf "%-15s %-40s\n" "Description:" "$desc"
			printf "%-15s %-40s\n" "Usage:" "$APP_NAME $usage_cmd $usage_msg"
		fi
		;;
	list) list ;;
	*)
		[[ "$cmd" != "config" ]] && validate_secret_backend

		if [ -f "$APP_USER_COMMAND_SCRIPTS/$cmd.sh" ]; then
			bash "$APP_USER_COMMAND_SCRIPTS/$cmd.sh" $@
		elif [ -f "bin/command/$cmd.sh" ]; then
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

function load_commands() {
	if [ ! -f "$APP_USER_COMMANDS" ]; then
		export APP_COMMANDS=$(<$APP_COMMANDS_FILE)
	else
		export APP_COMMANDS=$(yq e ". *+ load(\"$APP_USER_COMMANDS\")" $APP_COMMANDS_FILE)
	fi
}

function validate_secret_backend() {
	if [[ -n "$APPC_SECRET_BACKEND" && "$APPC_SECRET_BACKEND" != "0" ]]; then
		type -t "$APPC_SECRET_BACKEND"_load_secrets &>/dev/null || fail "Invalid secrets backend: $APPC_SECRET_BACKEND"
	fi
}
export -f validate_secret_backend

function load_secrets() {
	local secret_loader="${APPC_SECRET_BACKEND}_load_secrets"
	$secret_loader
}
export -f load_secrets

function handle_sigint() {
	echo "Exiting..."
	exit 1
}
trap handle_sigint SIGINT

ensure_data_dir
clean_user_config
match_config_to_template
load_user_config
ensure_temp
check_data_dir

if [[ "$1" != "config" ]]; then
	# If USER_DIR is set in config, confirm it is "correct" before using it.
	if [ -n "$APPC_USER_DIR" ] && [[ "$APPC_USER_DIR" != "0" ]]; then
		[ ! -d "$APPC_USER_DIR" ] && fail "User directory not set to a valid directory"
		export APP_USER_DIR="$APPC_USER_DIR"
	fi

	while getopts ":u:" opt; do
		case "$opt" in
		u)
			export APP_USER_DIR="${OPTARG}"
			;;
		*)
			fail "Unknown argument: $opt"
			;;
		esac
	done
	shift "$((OPTIND - 1))"

	export APP_USER_COMMANDS="$APP_USER_DIR/commands.yaml"
	export APP_USER_COMMAND_SCRIPTS="$APP_USER_DIR/commands"

fi

load_commands
command="$1"
shift

if [ -z "$command" ]; then
	echo "Missing command" && list && exit 1
elif ! echo "$APP_COMMANDS" | yq -e ".commands.$command" >/dev/null 2>&1; then
	echo "Unknown command: $command" && list && exit 1
fi

run_cmd $@
