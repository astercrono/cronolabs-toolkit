#!/usr/bin/env bash

subcommands=("install" "start", "serve" "stop" "cmd", "generate" "chat" "status")
SUBCOMMAND="$1"

if [[ ! " ${subcommands[@]} " =~ " $SUBCOMMAND" ]] || [ -z "$SUBCOMMAND" ]; then
	echo "Invalid llama command: $SUBCOMMAND"
	exit 1
fi

function install_ollama() {
	curl -fsSL https://ollama.com/install.sh | sh
}

function llama_send() {
	type="$1"
	msg="$2"

	if [ -z "$msg" ]; then
		echo "Missing require argument: MESSAGE"
		exit 1
	fi

	curl http://localhost:11434/api/$type -d '{
	"model": "llama3.2",
	"messages": [
		{ "role": "user", "content": "$msg" }
	]
	}'
}

case $SUBCOMMAND in
install)
	install_ollama
	;;
start)
	ollama run llama3.2
	;;
serve)
	ollama serve
	;;
generate)
	llama_send "generate" "$1"
	;;
chat)
	llama_send "chat" "$1"
	;;
stop)
	systemctl is-active --quiet ollama && sudo systemctl stop ollama
	;;
status)
	systemctl status ollama
	;;
cmd)
	ollama $@
	;;
esac
