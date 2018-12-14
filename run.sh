#!/bin/sh

set -eu
export LC_ALL=C

DOCKER_IMAGE_NAMESPACE=hectormolinero
DOCKER_IMAGE_NAME=winamp
DOCKER_IMAGE_VERSION=latest
DOCKER_IMAGE=${DOCKER_IMAGE_NAMESPACE}/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_VERSION}
DOCKER_CONTAINER=${DOCKER_IMAGE_NAME}
DOCKER_VOLUME="${DOCKER_CONTAINER}"-data

imageExists() { [ -n "$(docker images -q "$1")" ]; }
containerExists() { docker ps -aqf name="$1" --format '{{.Names}}' | grep -Fxq "$1"; }
containerIsRunning() { docker ps -qf name="$1" --format '{{.Names}}' | grep -Fxq "$1"; }

if ! imageExists "${DOCKER_IMAGE}"; then
	>&2 printf -- '%s\n' "${DOCKER_IMAGE} image doesn't exist!"
	exit 1
fi

if containerIsRunning "${DOCKER_CONTAINER}"; then
	printf -- '%s\n' "Stopping \"${DOCKER_CONTAINER}\" container..."
	docker stop "${DOCKER_CONTAINER}" >/dev/null
fi

if containerExists "${DOCKER_CONTAINER}"; then
	printf -- '%s\n' "Removing \"${DOCKER_CONTAINER}\" container..."
	docker rm "${DOCKER_CONTAINER}" >/dev/null
fi

if [ -d "${HOME}/Music" ]; then
	MUSIC_FOLDER="${HOME}/Music"
fi

if [ -d '/tmp/.X11-unix' ]; then
	X11_SOCKET_DIRECTORY='/tmp/.X11-unix'

	XAUTHORITY_FILE='/tmp/.Xauthority.docker.winamp'
	touch "${XAUTHORITY_FILE}"
	xauth nlist "${DISPLAY}" | sed -e 's/^..../ffff/' | xauth -f "${XAUTHORITY_FILE}" nmerge -

	if [ -d '/dev/dri' ]; then
		DEVICE_DRI='/dev/dri'
	fi

	#if [ -c '/dev/nvidiactl' ] && [ -c '/dev/nvidia0' ]; then
	#	DEVICE_NVIDIACTL='/dev/nvidiactl'
	#	DEVICE_NVIDIA0='/dev/nvidia0'
	#fi
fi

if [ -S "${XDG_RUNTIME_DIR-}/pulse/native" ]; then
	PULSEAUDIO_SOCKET="${XDG_RUNTIME_DIR-}/pulse/native"
fi

printf -- '%s\n' "Creating \"${DOCKER_CONTAINER}\" container..."
exec docker run --tty --interactive --rm \
	--name "${DOCKER_CONTAINER}" \
	--network none \
	--log-driver none \
	--mount type=volume,src="${DOCKER_VOLUME}",dst='/home/winamp/.wine' \
	${MUSIC_FOLDER+--mount type=bind,src="${MUSIC_FOLDER}",dst='/home/winamp/Music',ro} \
	${X11_SOCKET_DIRECTORY+ \
		--env DISPLAY="${DISPLAY}" \
		--mount type=bind,src="${X11_SOCKET_DIRECTORY}",dst='/tmp/.X11-unix',ro \
		--env XAUTHORITY='/home/winamp/.Xauthority' \
		--mount type=bind,src="${XAUTHORITY_FILE}",dst='/home/winamp/.Xauthority',ro \
		${DEVICE_DRI+--device "${DEVICE_DRI}":'/dev/dri':r} \
		${DEVICE_NVIDIACTL+--device "${DEVICE_NVIDIACTL}":'/dev/nvidiactl':r} \
		${DEVICE_NVIDIA0+--device "${DEVICE_NVIDIA0}":'/dev/nvidia0':r} \
	} \
	${PULSEAUDIO_SOCKET+ \
		--env PULSE_SERVER='/run/user/1000/pulse/native' \
		--mount type=bind,src="${PULSEAUDIO_SOCKET}",dst='/run/user/1000/pulse/native',ro \
	} \
	"${DOCKER_IMAGE}" "$@"
