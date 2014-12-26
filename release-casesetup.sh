#!/bin/bash -ex

export HOME=/home/gengs

WORKDIR=$(cd `dirname $0`; pwd)
cd $WORKDIR

TAG=$1
VER=$2

if [ -z $TAG -o -z $VER ]; then
	echo "USAGE: $0 [tag] [version]"
	exit 1
fi

./prepare.pl -t $TAG -v $VER -c 'common'
./prepare.pl -t $TAG -v $VER -c 'case'
./prepare.pl -t $TAG -v $VER -c 'setup'

./publish-case.sh $VER
./publish-setup.sh $VER
