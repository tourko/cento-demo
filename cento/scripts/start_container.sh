#!/bin/env sh

podman run -it --rm \
	--name cento \
	--privileged \
	--network=host \
	--ipc=host \
	--device=/dev/nt3gd \
	-v /var/run/napatech:/var/run/napatech \
	-v /dev/nt3gd:/dev/nt3gd \
	-v /opt/napatech3/lib:/opt/napatech3/lib \
	-v /opt/napatech3/bin:/opt/napatech3/bin \
	-v /opt/cento/config:/opt/cento/config \
	localhost/cento:latest "$@"

