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

# Create winamp group and user
ARG WINAMP_UID=1000
ARG WINAMP_GID=1000
RUN groupadd \
		--gid "${WINAMP_GID}" \
		winamp \
	&& useradd \
		--uid "${WINAMP_UID}" \
		--gid winamp \
		--groups audio,video \
		--home-dir /home/winamp \
		--create-home \
		winamp

WORKDIR /home/winamp
USER winamp:winamp

# Environment
ENV WINEPREFIX=/home/winamp/.wine
ENV WINEARCH=win32
ENV WINEDEBUG=fixme-all
ENV WINEDLLOVERRIDES=mscoree,mshtml=
ENV FREETYPE_PROPERTIES=truetype:interpreter-version=35

# Setup wine
RUN mkdir -p /tmp/setup/ "${WINEPREFIX}"
COPY --chown=winamp:winamp config/ /tmp/setup/config/
COPY --chown=winamp:winamp installers/ /tmp/setup/installers/
COPY --chown=winamp:winamp scripts/ /tmp/setup/scripts/
RUN timeout 240 /tmp/setup/scripts/wine-setup
RUN rm -rf /tmp/setup/

CMD ["wine", "/home/winamp/.wine/drive_c/Program Files/Winamp/winamp.exe"]
