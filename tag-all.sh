#!/bin/bash -ex

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
MANU=${5:-false}
set $ANDR $COMM $CASE $SETP $MANU

subs="android common case setup manual"

svn_dir=`cat conf/ar.conf | grep 'tag_root_dir' | awk -F'=' '{print $2}' | sed -e "s/.*'\(.*\)'.*/\1/"`
./svn-sweep $svn_dir

for sub in $subs; do
	doit=$1
	shift

	if [ ${doit} == 'true' ]; then
		./tag.pl -t ${TAG} -v ${VER} -c ${sub}
	fi
done
./tag.pl -t ${TAG} -v ${VER} -c preload
