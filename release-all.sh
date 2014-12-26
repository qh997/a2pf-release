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

shift; shift;

ANDR=${1:-false}
COMM=${2:-false}
CASE=${3:-false}
SETP=${4:-false}

svn_dir=`cat conf/ar.conf | grep 'rls_root_dir' | awk -F'=' '{print $2}' | sed -e "s/.*'\(.*\)'.*/\1/"`
svn_dir=${svn_dir}'/'${VER}
./clean
./svn-sweep $svn_dir

if [ $ANDR == 'true' ]; then
	./release-android.sh $TAG $VER
	touch adr_ok
fi

if [ $COMM == 'true' ]; then
	./prepare.pl -t $TAG -v $VER -c 'common'
	touch com_ok
fi

if [ $CASE == 'true' ]; then
	./prepare.pl -t $TAG -v $VER -c 'case'
	./publish-case.sh $VER
	touch cse_ok
fi

if [ $SETP == 'true' ]; then
	./prepare.pl -t $TAG -v $VER -c 'setup'
	./publish-setup.sh $VER
	touch stp_ok
fi

svn add --force ${svn_dir}'/*'
