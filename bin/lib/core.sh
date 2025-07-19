function corecount() {
	if command -v nproc &>/dev/null; then
		cores=$(nproc)
	elif command -v sysctl &>/dev/null; then
		cores=$(sysctl -n hw.ncpu)
	else
		cores=1
	fi

	echo "$cores"
}
export -f corecount
