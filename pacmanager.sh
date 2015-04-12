#!/usr/bin/bash -e

contains() {
	param=$1;
	shift;
	for elem in "$@";
	do
		[ "$param" = "$elem" ] && return 0;
	done;
	return 1
}

cleanup() {
	rm -rf "$temp_dir"
}

list_orphans() {
	source ./pkg-list.sh "$(hostname)"
	wanted_pkg=()
	known_groups=($(pacman -Sqg))

	i=1
	for pkg in "${input_pkgs[@]}"
	do
		echo -ne "\r[$i/${#input_pkgs[@]}]" >&2
		if contains "$pkg" "${known_groups[@]}"; then
			wanted_pkg+=($(pacman -Sgq "$pkg"))
		else
			wanted_pkg+=($pkg)
		fi
		let i=i+1
	done

	echo >&2

	pacman -Qqe | sort -u > "$temp_dir/installed_pkg.txt"

	printf "%s\n" "${wanted_pkg[@]}" | sort -u > "$temp_dir/wanted_pkg.txt"

	comm -13 "$temp_dir/wanted_pkg.txt" "$temp_dir/installed_pkg.txt"
}

deinstall_orphans() {
	orphans=($(list_orphans))
	if [ -z "${orphans[@]}" ]; then
		echo "No packages to deinstall." >&2
		exit 0
	fi
	sudo pacman -Rdd "${orphans[@]}"
}

install_packages() {
	source ./pkg-list.sh "$(hostname)"
	if [ ! -z "$aflag" ]; then
		if ! type "yaourt" > /dev/null; then
			echo "Error: yaourt is not installed!" >&2
			exit 3
		fi
		yaourt -Syua "${input_pkgs[@]}" --needed
	else
		sudo pacman -Syu "${input_pkgs[@]}" --needed
	fi
}

print_usage() {
	echo "Usage: $0 -l" >&2
	echo "       $0 -d" >&2
	echo "       $0 -i [-a]" >&2
}

if [ $# -eq 0 ]; then
	print_usage
	exit 2
fi

while getopts ":lhdia" opt; do
	case $opt in
		h)
			print_usage
			exit 0
			;;
		l)
			action="l"
			;;
		d)
			action="d"
			;;
		i)
			action="i"
			;;
		a)
			aflag=1
			;;
		\?)
			echo "Invalid option: -$OPTARG" >&2
			print_usage
			exit 2
			;;
	esac
done

if [ $OPTIND -eq 1 ]; then
	echo "No option specified" >&2
	print_usage
	exit 2
fi

if [ $((OPTIND - 1)) -ne $# ]; then
	shift $((OPTIND - 1))
	for arg in "$@"
	do
		echo "Ignored extra argument: '$arg'" >&2
	done
fi

trap cleanup EXIT
temp_dir=$(mktemp -d /tmp/pacmanager.XXXX)

if [ $action = "l" ]; then
	list_orphans
elif [ $action = "d" ]; then
	deinstall_orphans
elif [ $action = "i" ]; then
	install_packages
else
	echo "Internal error: \$action should not be '$action'" >&2
	exit 1
fi
