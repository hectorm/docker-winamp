#!/bin/sh

set -eu
export LC_ALL=C

rm -f ./MD5SUMS ./SHA1SUMS ./SHA256SUMS
find ./ \
	-type f \
	-not '(' \
		-name 'checksums.sh' \
		-or -name 'README.md' \
		-or -name 'MD5SUMS' \
		-or -name 'SHA1SUMS' \
		-or -name 'SHA256SUMS' \
	')' \
	-exec sh -c 'md5sum "$1" >> ./MD5SUMS' _ '{}' ';' \
	-exec sh -c 'sha1sum "$1" >> ./SHA1SUMS' _ '{}' ';' \
	-exec sh -c 'sha256sum "$1" >> ./SHA256SUMS' _ '{}' ';'
