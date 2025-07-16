#!/usr/bin/env bash

CLUSTER_HOSTNAME="clt.cronolabs.net"

# Format: Container name, OS, Version, Arch, Template, Web Proxy Target
LXC_NAME_PROXY="proxy.test:fedora:41:amd64:proxy"
LXC_NAME_DB="db.test:fedora:41:amd64:db"
LXC_NAME_WIKI="wiki.test:fedora:41:amd64:wiki:proxy.test"

CONTAINERS=($LXC_NAME_PROXY $LXC_NAME_DB $LXC_NAME_WIKI)

sudo -v

[ $CLT_DRYRUN = 1 ] && echo "** DRYRUN MODE ENABLED **"

TEST_STATUS=0
TEST_FAIL_REASONS=()

function add_failure() {
	TEST_STATUS=1
	TEST_FAIL_REASONS+=("Failure: $@")
}

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
		sleep 3
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
		web_proxy_target="${values[5]}"

		print_submessage "Adding $name"
		if [ ! $CLT_DRYRUN = 1 ]; then
			ip_address=$(lxc_ip $name)

			if ! sudo grep -q "$name" /etc/hosts; then
				host_line="$ip_address $(fqdn $name)"
				echo "$host_line" | sudo tee -a /etc/hosts >/dev/null
				sudo lxc-attach -n "$name" -- bash -c "echo $host_line | sudo tee -a /etc/hosts >/dev/null"

				if [ -n "$web_proxy_target" ]; then
					proxy_ip=$(lxc_ip $web_proxy_target)
					echo "$proxy_ip web.$(fqdn $name)" | sudo tee -a /etc/hosts >/dev/null
				fi

			fi
		fi
	done
}

function remove_from_file() {
	file="$1"
	print_h2 "Updating $file"
	for container in "${CONTAINERS[@]}"; do
		print_submessage "Removing $name"

		if [ ! $CLT_DRYRUN = 1 ]; then
			values=($(read_lxc_definition $container))
			name="${values[0]}"
			[ $CLT_DRYRUN = 0 ] && sudo sed -i "/$name/d" "$file"
		fi

	done
}

function test_pings() {
	print_h2 "Performing ping tests"
	for container in "${CONTAINERS[@]}"; do
		values=($(read_lxc_definition $container))
		name="${values[0]}"

		ping -c 5 "$(fqdn $name)" >/dev/null &
		spinner $! "    Checking $(fqdn $name)" 1

		[ $? -ne 0 ] && add_failure "Ping check for $(fqdn $name)"
	done
}

function ssh_cmd() {
	container_name="$1"
	shift
	ssh -o StrictHostKeyChecking=no root@$(fqdn $container_name) "$@"
}

function ssh_key() {
	keys=("$HOME/.ssh/id_ed25519.pub" "$HOME/.ssh/id_rsa.pub")

	for key in "${keys[@]}"; do
		if [ -f "$key" ]; then
			cat "$key"
			return 0
		fi
	done

	return 1
}

function prepare_container() {
	name="$1"

	sudo lxc-attach -n "$name" -- sudo dnf update -y
	sudo lxc-attach -n "$name" -- sudo dnf install -y openssh-server python rsync
	sudo lxc-attach -n "$name" -- sudo systemctl start sshd
	sudo lxc-attach -n "$name" -- sudo mkdir -p /root/.ssh
	sudo lxc-attach -n "$name" -- bash -c "echo $(ssh_key) >> /root/.ssh/authorized_keys"
	sudo lxc-attach -n "$name" -- chmod 600 /root/.ssh/authorized_keys
	sudo lxc-attach -n "$name" -- chmod 700 /root/.ssh

	rsync -av -e "ssh -o StrictHostKeyChecking=no" --exclude=".git" $CLT_BASE root@$(fqdn $name):/root
	sudo lxc-attach -n "$name" -- /root/cronolabs-toolkit/bin/clt install
}

function prepare_containers() {
	print_h2 "Preparing containers for provisioning"

	for container in "${CONTAINERS[@]}"; do
		values=($(read_lxc_definition $container))
		name="${values[0]}"

		prepare_container "$name" >/dev/null 2>&1 &
		spinner $! "    Preparing $name"
	done
}

function provision_containers() {
	echo "Run provisioning against container"
	for container in "${CONTAINERS[@]}"; do
		values=($(read_lxc_definition $container))
		name="${values[0]}"
		template="${values[4]}"
		# ssh_cmd $name "clt provision fedora -g server -c lxc -t $template >/dev/null" >/dev/null &
		sudo lxc-attach -n "$name" -- bash -c "PROXY_SSL_DHPARAM_FAST=1 CLUSTER_HOSTNAME='$CLUSTER_HOSTNAME' PROXY_SSL_ORGUNIT='Test Lab' SYSTEM_TYPE=fedora GROUP=server CATEGORY=lxc /root/cronolabs-toolkit/bin/clt provision fedora -g server -c lxc -t $template >/dev/null" &
		spinner $! "Provisioning $name"
	done
}

function catch_sigint() {
	echo "SIGINT: Exiting gracefully"
	cleanup_containers
	remove_from_file "/etc/hosts"
	remove_from_file "$HOME/.ssh/known_hosts"
	exit 1
}

trap catch_sigint SIGINT

cleanup_containers
remove_from_file "/etc/hosts"
remove_from_file "$HOME/.ssh/known_hosts"

create_containers
add_hosts
prepare_containers
provision_containers
test_pings

echo "Todo: start testing containers here..."
breakpoint

cleanup_containers
remove_from_file "/etc/hosts"
remove_from_file "$HOME/.ssh/known_hosts"

# TODO: Print failures out

if [ ${#TEST_FAIL_REASONS[@]} -gt 0 ]; then
	echo ""
	echo "Failure Reasons:"
	for reason in "${TEST_FAIL_REASONS[@]}"; do
		echo "    $reason"
	done
fi

# TODO:
#     - Run some test commands / scripts to confirm all services are working correctly
