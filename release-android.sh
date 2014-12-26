#!/bin/bash -ex

WORKDIR=$(cd `dirname $0`; pwd)
cd $WORKDIR

TAG=$1
VER=$2

if [ -z $TAG -o -z $VER ]; then
	echo "USAGE: $0 [tag] [version]"
	exit 1
fi

./prepare.pl -t "$TAG" -v "$VER" -c 'android'
./prebuild.pl -t "$TAG" -v "$VER" -c 'android'
./publish-android.sh "$VER"
