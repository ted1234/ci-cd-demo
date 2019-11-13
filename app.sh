#!/bin/sh
trap 'echo Exiting on SIGTERM; exit 0;' TERM

# Simulate these being baked into a binary
VERSION=
VCS_COMMIT=

# Alpine running in a container specific
ip=$(ip addr | grep 'inet.*eth0' | cut -d ' ' -f 6 | sed 's|/..||')

# Loop
while true; do
	echo "$(date +"%H:%M:%S") [${ip}] Doing work for v${VERSION} on commit ${VCS_COMMIT}"
	sleep 1s
done
