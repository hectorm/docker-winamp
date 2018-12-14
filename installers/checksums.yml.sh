#!/bin/sh

set -eu

printf 'installers:\n' && find "$(dirname "$(readlink -f "$0")")" \
	-type f \( -name '*.exe' -or -name '*.zip' \) \
	-exec sh -s -eu '{}' '+' <<-'EOF'
		_IFS=$IFS; IFS="$(printf '\nx')"; IFS="${IFS%x}"
		for file in $(printf -- '%s\n' "$@" | sort); do
			printf -- '  - %s:\n'          "$(basename -- "${file}")"
			printf -- '      md5: %s\n'    "$(md5sum -- "${file}" | awk '{print $1}')"
			printf -- '      sha1: %s\n'   "$(sha1sum -- "${file}" | awk '{print $1}')"
			printf -- '      sha256: %s\n' "$(sha256sum -- "${file}" | awk '{print $1}')"
		done
		IFS=$_IFS
	EOF
