FROM debian:testing

# Install dependencies
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
	&& apt-get install --assume-yes --no-install-recommends \
		apt-transport-https \
		apt-utils \
		ca-certificates \
		curl \
		gnupg \
	&& dpkg --add-architecture i386 \
	&& { \
		echo 'deb http://deb.debian.org/debian/ testing main contrib'; \
		echo 'deb http://deb.debian.org/debian/ testing-updates main contrib'; \
		echo 'deb http://security.debian.org/ testing/updates main contrib'; \
		echo 'deb https://dl.winehq.org/wine-builds/debian/ testing main'; \
	} > /etc/apt/sources.list \
	&& curl -fsSL 'https://dl.winehq.org/wine-builds/Release.key' | apt-key add - \
	&& echo 'ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true' | debconf-set-selections \
	&& apt-get update \
	&& apt-get install --assume-yes --no-install-recommends \
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

# Setup wine
ENV WINEPREFIX=/home/winamp/.wine
ENV WINEARCH=win32
ENV WINEDEBUG=fixme-all
ENV WINEDLLOVERRIDES=mscoree,mshtml=
ENV FREETYPE_PROPERTIES=truetype:interpreter-version=35
COPY --chown=winamp:winamp scripts/wine-setup /tmp/wine-setup
COPY --chown=winamp:winamp installers/ /tmp/installers/
RUN timeout 240 /tmp/wine-setup && rm -rf /tmp/wine-setup /tmp/installers/

CMD ["wine", "/home/winamp/.wine/drive_c/Program Files/Winamp/winamp.exe"]
