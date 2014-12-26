#!/bin/bash -e

ver=$1

ifile='pb_android'
publish_dir=`cat conf/ar.conf | grep 'rls_root_dir' | awk -F'=' '{print $2}' | sed -e "s/.*'\(.*\)'.*/\1/"`
publish_dir=$publish_dir'/'${ver}'/apk/'

if [ ! -e ${publish_dir} ]; then
	echo "ERROR - Cannot found ${publish_dir}."
	exit -1
fi

if [ ! -e ${ifile} ]; then
	echo "ERROR - Cannot found ${ifile}."
	exit -1
fi

echo rm -rf ${publish_dir}
echo mkdir -p ${publish_dir}

err=0
for line in `awk -F: '{print $2 "/" $3}' ${ifile}`; do
	filename=$(basename "$line")
	if [ -e ${line} ]; then
		rm -rf "${publish_dir}${filename}"
		cp -r "$line" "${publish_dir}"
	else
		echo "ERROR - Cannot found [$line]"
		err=1
	fi
done

rm -rf ${ifile}

if [ $err -ne 0 ]; then
	exit 1
fi
