#!/bin/sh

set -eu

CONTAINER_DATA_VOLUME='winamp-data'
CONTAINER_DATA_DIRECTORY='/home/winamp/.wine'

if [ -d "${HOME}/Music" ]; then
	HOST_MUSIC_FOLDER="${HOME}/Music"
	CONTAINER_MUSIC_FOLDER='/home/winamp/Music'
fi

if [ -d '/tmp/.X11-unix' ]; then
	HOST_X11_SOCKET_DIRECTORY='/tmp/.X11-unix'
	CONTAINER_X11_SOCKET_DIRECTORY="${HOST_X11_SOCKET_DIRECTORY}"

	HOST_XAUTHORITY_FILE='/tmp/.Xauthority.docker.winamp'
	CONTAINER_XAUTHORITY_FILE='/home/winamp/.Xauthority'
	touch "${HOST_XAUTHORITY_FILE}"
	xauth nlist "${DISPLAY}" | sed -e 's/^..../ffff/' | xauth -f "${HOST_XAUTHORITY_FILE}" nmerge -

	if [ -S '/var/run/dbus/system_bus_socket' ]; then
		HOST_DBUS_SYSTEM_SOCKET='/var/run/dbus/system_bus_socket'
		CONTAINER_DBUS_SYSTEM_SOCKET="${HOST_DBUS_SYSTEM_SOCKET}"

		if [ -S "${XDG_RUNTIME_DIR:-}/bus" ]; then
			HOST_DBUS_SOCKET="${XDG_RUNTIME_DIR:-}/bus"
			CONTAINER_DBUS_SOCKET='/run/user/1000/bus'
		fi
	fi
fi

if [ -S "${XDG_RUNTIME_DIR:-}/pulse/native" ]; then
	HOST_PULSEAUDIO_SOCKET="${XDG_RUNTIME_DIR}/pulse/native"
	CONTAINER_PULSEAUDIO_SOCKET='/run/user/1000/pulse/native'
fi

docker run --tty --interactive --rm \
	--name winamp \
	--network none \
	--mount type=volume,src="${CONTAINER_DATA_VOLUME}",dst="${CONTAINER_DATA_DIRECTORY}" \
	${HOST_MUSIC_FOLDER:+ \
		--mount type=bind,src="${HOST_MUSIC_FOLDER}",dst="${CONTAINER_MUSIC_FOLDER}",ro \
	} \
	${HOST_X11_SOCKET_DIRECTORY:+ \
		--mount type=bind,src="${HOST_X11_SOCKET_DIRECTORY}",dst="${CONTAINER_X11_SOCKET_DIRECTORY}",ro \
		--env DISPLAY="${DISPLAY}" \
		--mount type=bind,src="${HOST_XAUTHORITY_FILE}",dst="${CONTAINER_XAUTHORITY_FILE}",ro \
		--env XAUTHORITY="${CONTAINER_XAUTHORITY_FILE}" \
		${HOST_DBUS_SYSTEM_SOCKET:+ \
			--mount type=bind,src="${HOST_DBUS_SYSTEM_SOCKET}",dst="${CONTAINER_DBUS_SYSTEM_SOCKET}",ro \
			${HOST_DBUS_SOCKET:+ \
				--mount type=bind,src="${HOST_DBUS_SOCKET}",dst="${CONTAINER_DBUS_SOCKET}",ro \
				--env DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS}" \
				--env DBUS_STARTER_ADDRESS="${DBUS_STARTER_ADDRESS}" \
				--env DBUS_STARTER_BUS_TYPE="${DBUS_STARTER_BUS_TYPE}" \
			} \
		} \
	} \
	${HOST_PULSEAUDIO_SOCKET:+ \
		--mount type=bind,src="${HOST_PULSEAUDIO_SOCKET}",dst="${CONTAINER_PULSEAUDIO_SOCKET}",ro \
		--env PULSE_SERVER="${CONTAINER_PULSEAUDIO_SOCKET}" \
	} \
	winamp "$@"
