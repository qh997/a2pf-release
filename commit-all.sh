#!/bin/bash -e

export HOME=/home/gengs

WORKDIR=$(cd `dirname $0`; pwd)
cd $WORKDIR

TAG=$1
VER=$2
STR=$3

if [[ -z $TAG || -z $VER || ! $STR = 'COMMIT' ]]; then
	echo "USAGE: $0 [tag] [version] COMMIT true true ture ture"
	exit 1
fi

shift; shift; shift;

ANDR=${1:-false}
COMM=${2:-false}
CASE=${3:-false}
SETP=${4:-false}

if [[ ! $ANDR == 'true' || ! $COMM == 'true' || ! $CASE == 'true' || ! $SETP == 'true' ]]; then
	echo "USAGE: $0 [tag] [version] COMMIT true true ture ture"
	exit 1
fi

if [[ ! -e adr_ok || ! -e com_ok || ! -e cse_ok || ! -e stp_ok ]]; then
	echo "ERROR - Missing *_ok file, run release-all.sh frist."
	exit 1
fi

svn_dir=`cat conf/ar.conf | grep 'rls_root_dir' | awk -F'=' '{print $2}' | sed -e "s/.*'\(.*\)'.*/\1/"`
svn_dir=${svn_dir}'/'${VER}
svn_cer=`cat conf/ar.conf | grep 'svn_cer' | awk -F'=' '{print $2}' | sed -e "s/.*'\(.*\)'.*/\1/"`
svn commit -m "Release for ${VER} on <${TAG}>." ${svn_cer} "${svn_dir}"

./clean
