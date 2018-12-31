FROM ubuntu:18.04

# Install system packages
RUN export DEBIAN_FRONTEND=noninteractive \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends \
		apt-transport-https \
		apt-utils \
		ca-certificates \
		curl \
		gnupg \
	&& dpkg --add-architecture i386 \
	&& curl -fsSL 'https://dl.winehq.org/wine-builds/winehq.key' | apt-key add - \
	&& printf '%s\n' 'deb https://dl.winehq.org/wine-builds/ubuntu/ bionic main' > /etc/apt/sources.list.d/wine.list \
	&& printf '%s\n' 'ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true' | debconf-set-selections \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends \
		fonts-dejavu \
		fonts-liberation \
		hicolor-icon-theme \
		libgl1-mesa-dri \
		libgl1-mesa-dri:i386 \
		libgl1-mesa-glx \
		libgl1-mesa-glx:i386 \
		mesa-utils \
		pulseaudio \
		ttf-mscorefonts-installer \
		unzip \
		winehq-devel \
		xauth \
		xvfb \
	&& rm -rf /var/lib/apt/lists/*

# Create socket folder for X server
RUN mkdir /tmp/.X11-unix \
	&& chmod 1777 /tmp/.X11-unix \
	&& chown root /tmp/.X11-unix

# Create wine group and user
ARG WINE_UID=1000
ARG WINE_GID=1000
RUN groupadd \
		--gid "${WINE_GID}" \
		wine \
	&& useradd \
		--uid "${WINE_UID}" \
		--gid wine \
		--groups audio,video \
		--home-dir /home/wine \
		--create-home \
		wine

WORKDIR /home/wine
USER wine:wine

# Environment
ENV WINEPREFIX=/home/wine/.wine
ENV WINEARCH=win32
ENV WINEDEBUG=fixme-all
ENV WINEDLLOVERRIDES=mscoree,mshtml=
ENV FREETYPE_PROPERTIES=truetype:interpreter-version=35

# Setup wine
RUN mkdir -p /tmp/setup/ "${WINEPREFIX}"
COPY --chown=wine:wine config/ /tmp/setup/config/
COPY --chown=wine:wine installers/ /tmp/setup/installers/
COPY --chown=wine:wine scripts/ /tmp/setup/scripts/
RUN timeout 240 /tmp/setup/scripts/wine-setup
RUN rm -rf /tmp/setup/

CMD ["wine", "/home/wine/.wine/drive_c/Program Files/Winamp/winamp.exe"]
