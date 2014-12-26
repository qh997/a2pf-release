#!/bin/bash -ex

WORKDIR=$(cd `dirname $0`; pwd)
cd $WORKDIR

TAG=$1
REMOVE=${2:-0}

if [ -z $TAG ]; then
	echo "USAGE: $0 TAG [1] "
	exit 1
fi

TAG_URL='http://10.1.42.140/svn/apf_apn_ten_svn_src/arm/tags/'
BASEDIR="/home/gengs/projects/a2pf-tag/"

if [ ${REMOVE} -ne 0 ]; then
	rm -rf ${BASEDIR}${TAG}
	echo "Start to get <${TAG}>"
	set -v
	svn export --username 'gengs' --password 'qh997@NEU3' \
		"${TAG_URL}${TAG}" "${BASEDIR}${TAG}"
	set +v
else
	echo "Nothing to be done."
fi
