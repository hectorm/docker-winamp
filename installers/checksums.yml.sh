#!/bin/sh

set -eu

cd "$(dirname "$(readlink -f "$0")")"

printf -- '%s\n' 'installers:'
for file in *; do
	[ "${file#checksums.yml}" != "${file}" ] && continue;
	printf -- '%s\n' "  - ${file}:"
	printf -- '%s\n' "      md5: $(md5sum -- "${file}" | awk '{print $1}')"
	printf -- '%s\n' "      sha1: $(sha1sum -- "${file}" | awk '{print $1}')"
	printf -- '%s\n' "      sha256: $(sha256sum -- "${file}" | awk '{print $1}')"
done
