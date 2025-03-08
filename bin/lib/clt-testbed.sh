#!/usr/bin/env bash

LXC_NAME_PROXY="proxy.test:fedora:41:amd64"
LXC_NAME_DB="db.test:fedora:41:amd64"
LXC_NAME_WIKI="wiki.test:fedora:41:amd64"

CONTAINERS=($LXC_NAME_PROXY $LXC_NAME_DB $LXC_NAME_WIKI)

sudo -v

[ $CLT_DRYRUN = 1 ] && echo "** DRYRUN MODE ENABLED **"

function print_h2() {
	echo "> $@"
}

function print_submessage() {
	echo "    $@"
}

function run_lxc() {
	cmd="$1"
	shift

	if [ "$CLT_DRYRUN" = 1 ]; then
		print_submessage "sudo lxc-$cmd $@"
		return $?
	else
		sudo lxc-$cmd $@
		return $?
	fi
}

function read_lxc_definition() {
	IFS=':'
	read -ra split <<<"$1"
	echo "${split[@]}"
}

function cleanup_containers() {
	print_h2 "Cleaning up containers"

	if ! sudo lxc-ls | grep -q ".test"; then
		print_submessage "Nothing to cleanup"
		return 0
	fi

	for container in "${CONTAINERS[@]}"; do
		values=($(read_lxc_definition $container))
		name="${values[0]}"

		run_lxc ls | grep -q "$name"

		if [ $? = 0 ]; then
			run_lxc destroy -f --name $name &
			spinner $! "    Removing $name"
		fi
	done
}

function create_containers() {
	print_h2 "Creating containers"
	for container in "${CONTAINERS[@]}"; do
		values=($(read_lxc_definition $container))

		name="${values[0]}"
		dist="${values[1]}"
		release="${values[2]}"
		arch="${values[3]}"

		run_lxc create --name "$name" --template download -- --dist $dist --release $release --arch $arch >/dev/null &
		spinner $! "    [Downloading] $name"

		run_lxc start --name "$name" >/dev/null &
		spinner $! "    [Starting] $name"
	done
}

function lxc_ip() {
	sudo lxc-info -n $1 -iH
}

function add_hosts() {
	print_h2 "Updating /etc/hosts"

	for container in "${CONTAINERS[@]}"; do
		values=($(read_lxc_definition $container))
		name="${values[0]}"

		print_submessage "Adding $name"
		if [ ! $CLT_DRYRUN = 1 ]; then
			ip_address=$(lxc_ip $name)

			if ! sudo grep -q "$name" /etc/hosts; then
				[ $CLT_DRYRUN = 0 ] && echo "$ip_address $name" | sudo tee -a /etc/hosts >/dev/null
			fi
		fi
	done
}

function remove_hosts() {
	print_h2 "Updating /etc/hosts"
	for container in "${CONTAINERS[@]}"; do
		print_submessage "Removing $name"

		if [ ! $CLT_DRYRUN = 1 ]; then
			values=($(read_lxc_definition $container))
			name="${values[0]}"
			[ $CLT_DRYRUN = 0 ] && sudo sed -i "/$name/d" /etc/hosts
		fi

	done
}

function test_pings() {
	print_h2 "Performing ping tests"
	status=0
	for container in "${CONTAINERS[@]}"; do
		values=($(read_lxc_definition $container))
		name="${values[0]}"

		ping -c 10 "$name" >/dev/null &
		spinner $! "    Checking $name" 1
		if [ $? -ne 0 ]; then
			status=1
		fi
	done
	return $status
}

function catch_sigint() {
	echo "SIGINT: Exiting gracefully"
	cleanup_containers
	exit 1
}

trap catch_sigint SIGINT

cleanup_containers
create_containers
add_hosts
test_pings
echo "Todo: Run provisioning scripts here..."
echo "Todo: start testing containers here..."
remove_hosts
cleanup_containers

# TODO:
#     - Need to modify /etc/hosts with the lxc hostnames and IPs
#     - confirm that each container can be pinged.
#     - run a provision command on each container
#     - Run some test commands / scripts to confirm all services are working correctly
