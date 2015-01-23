#!/bin/bash -ex

WORKDIR=$(cd `dirname $0`; pwd)
cd $WORKDIR

TAG=$1
VER=$2
CPL=${3:-true}

if [ -z $TAG -o -z $VER ]; then
	echo "USAGE: $0 [tag] [version]"
	exit 1
fi

./prepare.pl -t "$TAG" -v "$VER" -c 'android'
./prebuild.pl -t "$TAG" -v "$VER" -c 'android'

if [ ${CPL} = 'true' ]; then
	if [ -n $URL ]; then
		sudo mail-maker -s rls-adr-cpl-start -f VERSION="${VER}" MAIN-VERSION="${TAG}" URL="${URL}"
	fi

	./build-base.sh "$TAG"
	sudo mail-maker -s rls-adr-cpl-success -f VERSION="${VER}" MAIN-VERSION="${TAG}"
fi
