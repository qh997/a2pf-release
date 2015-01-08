#!/bin/bash -e

ver=$1

if [ -z ${ver} ]; then
	echo "USAGE: $0 VER"
	exit 1
fi

ifile='pb_android'
release_dir=`cat conf/ar.conf | grep 'rls_root_dir' | awk -F'=' '{print $2}' | sed -e "s/.*'\(.*\)'.*/\1/"`
release_dir=$release_dir'/'${ver}'/apk/'
publish_dir=`cat conf/ar.conf | grep 'pul_root_dir' | awk -F'=' '{print $2}' | sed -e "s/.*'\(.*\)'.*/\1/"`
publish_dir=$publish_dir'/'${ver}'/apk/'

if [ ! -e ${ifile} ]; then
	echo "ERROR - Cannot found ${ifile}."
	exit 1
fi

rm -rf ${release_dir}
mkdir -p ${release_dir}
if [ ! -e ${release_dir} ]; then
	echo "ERROR - Cannot found ${release_dir}."
	exit 1
fi

sudo rm -rf ${publish_dir}
sudo mkdir -p ${publish_dir}
if [ ! -e ${publish_dir} ]; then
	echo "ERROR - Cannot found ${publish_dir}."
	exit 1
fi

err=0
for line in `awk -F: '{print $2 "/" $3}' ${ifile}`; do
	filename=$(basename "$line")
	if [ -e ${line} ]; then
		rm -rf "${release_dir}${filename}"
		cp -r "$line" "${release_dir}"
		sudo rm -rf "${publish_dir}${filename}"
		sudo cp -r "$line" "${publish_dir}"
	else
		echo "ERROR - Cannot found [$line]"
		err=1
	fi
done

rm -rf ${ifile}

if [ $err -ne 0 ]; then
	exit 1
fi
