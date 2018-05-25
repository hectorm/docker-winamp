#!/bin/sh

set -eu

CONTAINER_DATA_VOLUME='winamp-data'
CONTAINER_DATA_DIRECTORY='/home/winamp/.wine'

HOST_MUSIC_FOLDER="${HOME}/Music"
if [ -d "${HOST_MUSIC_FOLDER}" ]; then
	CONTAINER_MUSIC_FOLDER='/home/winamp/Music'
fi

HOST_X11_SOCKET_DIRECTORY='/tmp/.X11-unix'
if [ -d "${HOST_X11_SOCKET_DIRECTORY}" ]; then
	CONTAINER_X11_SOCKET_DIRECTORY="${HOST_X11_SOCKET_DIRECTORY}"

	HOST_XAUTHORITY_FILE='/tmp/.Xauthority.docker.winamp'
	CONTAINER_XAUTHORITY_FILE='/home/winamp/.Xauthority'
	touch "${HOST_XAUTHORITY_FILE}"
	xauth nlist "${DISPLAY}" | sed -e 's/^..../ffff/' | xauth -f "${HOST_XAUTHORITY_FILE}" nmerge -

	HOST_DEVICE_DRI='/dev/dri'
	if [ -d "${HOST_DEVICE_DRI}" ]; then
		CONTAINER_DEVICE_DRI="${HOST_DEVICE_DRI}"
	fi

	#HOST_DEVICE_NVIDIACTL='/dev/nvidiactl'
	#HOST_DEVICE_NVIDIA0='/dev/nvidia0'
	#if [ -c "${HOST_DEVICE_NVIDIACTL}" ] && [ -c "${HOST_DEVICE_NVIDIA0}" ]; then
	#	CONTAINER_DEVICE_NVIDIACTL="${HOST_DEVICE_NVIDIACTL}"
	#	CONTAINER_DEVICE_NVIDIA0="${HOST_DEVICE_NVIDIA0}"
	#fi
fi

HOST_PULSEAUDIO_SOCKET="${XDG_RUNTIME_DIR-}/pulse/native"
if [ -S "${HOST_PULSEAUDIO_SOCKET}" ]; then
	CONTAINER_PULSEAUDIO_SOCKET='/run/user/1000/pulse/native'
fi

docker run --tty --interactive --rm \
	--name winamp \
	--network none \
	${CONTAINER_DATA_VOLUME:+ \
		--mount type=volume,src="${CONTAINER_DATA_VOLUME}",dst="${CONTAINER_DATA_DIRECTORY}" \
	} \
	${CONTAINER_MUSIC_FOLDER:+ \
		--mount type=bind,src="${HOST_MUSIC_FOLDER}",dst="${CONTAINER_MUSIC_FOLDER}",ro \
	} \
	${CONTAINER_X11_SOCKET_DIRECTORY:+ \
		--mount type=bind,src="${HOST_X11_SOCKET_DIRECTORY}",dst="${CONTAINER_X11_SOCKET_DIRECTORY}",ro \
		--env DISPLAY="${DISPLAY}" \
		--mount type=bind,src="${HOST_XAUTHORITY_FILE}",dst="${CONTAINER_XAUTHORITY_FILE}",ro \
		--env XAUTHORITY="${CONTAINER_XAUTHORITY_FILE}" \
		${CONTAINER_DEVICE_DRI:+ \
			--device "${HOST_DEVICE_DRI}":"${CONTAINER_DEVICE_DRI}":r \
		} \
		${CONTAINER_DEVICE_NVIDIACTL:+ \
			--device "${HOST_DEVICE_NVIDIACTL}":"${CONTAINER_DEVICE_NVIDIACTL}":r \
			--device "${CONTAINER_DEVICE_NVIDIA0}":"${CONTAINER_DEVICE_NVIDIA0}":r \
		} \
		${CONTAINER_DBUS_SYSTEM_SOCKET:+ \
			--mount type=bind,src="${HOST_DBUS_SYSTEM_SOCKET}",dst="${CONTAINER_DBUS_SYSTEM_SOCKET}",ro \
			${CONTAINER_DBUS_SOCKET:+ \
				--mount type=bind,src="${HOST_DBUS_SOCKET}",dst="${CONTAINER_DBUS_SOCKET}",ro \
				--env DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS}" \
				--env DBUS_STARTER_ADDRESS="${DBUS_STARTER_ADDRESS}" \
				--env DBUS_STARTER_BUS_TYPE="${DBUS_STARTER_BUS_TYPE}" \
			} \
		} \
	} \
	${CONTAINER_PULSEAUDIO_SOCKET:+ \
		--mount type=bind,src="${HOST_PULSEAUDIO_SOCKET}",dst="${CONTAINER_PULSEAUDIO_SOCKET}",ro \
		--env PULSE_SERVER="${CONTAINER_PULSEAUDIO_SOCKET}" \
	} \
	winamp "$@"
