#!/bin/bash -ex

export HOME=/home/gengs

WORKDIR=$(cd `dirname $0`; pwd)
cd $WORKDIR

TAG=$1
VER=$2
shift; shift;

ANDR=${1:-false}
COMM=${2:-false}
CASE=${3:-false}
SETP=${4:-false}

svn_dir=`cat conf/ar.conf | grep 'rls_root_dir' | awk -F'=' '{print $2}' | sed -e "s/.*'\(.*\)'.*/\1/"`
./clean
./svn-sweep $svn_dir

if [ $ANDR == 'true' ]; then
	./release-android.sh $TAG $VER
fi

if [ $COMM == 'true' ]; then
	./prepare.pl -t $TAG -v $VER -c 'common'
fi

if [ $CASE == 'true' ]; then
	./prepare.pl -t $TAG -v $VER -c 'case'
	./publish-case.sh $VER
fi

if [ $SETP == 'true' ]; then
	./prepare.pl -t $TAG -v $VER -c 'setup'
	./publish-setup.sh $VER
fi
