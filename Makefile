#!/usr/bin/make -f

MKFILE_RELPATH := $(shell printf -- '%s' '$(MAKEFILE_LIST)' | sed 's|^\ ||')
MKFILE_ABSPATH := $(shell readlink -f -- '$(MKFILE_RELPATH)')
MKFILE_DIR := $(shell dirname -- '$(MKFILE_ABSPATH)')

.PHONY: all \
	build build-image \
	clean clean-image clean-dist

all: build

build: dist/winamp.tgz

build-image:
	docker build \
		--rm \
		--tag winamp \
		'$(MKFILE_DIR)'

dist/:
	mkdir -p dist

dist/winamp.tgz: dist/ build-image
	docker save winamp | gzip > dist/winamp.tgz

clean: clean-image clean-dist

clean-image:
	-docker rmi winamp

clean-dist:
	rm -f dist/winamp.tgz
	-rmdir dist
