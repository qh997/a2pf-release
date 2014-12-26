#!/bin/bash -ex

WORKDIR=$(cd `dirname $0`; pwd)
cd $WORKDIR

TAG=$1

if [ -z $TAG ]; then
	echo "USAGE: $0 [tag]"
	exit 1
fi

BUILDDIR=`cat conf/ar.conf | grep 'base_root_dir' | awk -F'=' '{print $2}' | sed -e "s/.*'\(.*\)'.*/\1/"`
BUILDDIR="${BUILDDIR}/${TAG}"

if [ ! -d ${BUILDDIR} ]; then
	echo "ERROR - Cannot found base[${BUILDDIR}]"
	exit 1
fi

cd ${BUILDDIR}
/bin/bash build_all.sh
