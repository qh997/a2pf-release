#!/bin/bash

# pylint --generate-rcfile > pylint.conf

ver=$1

if [ -z ${ver} ]; then
	echo "USAGE: $0 VER"
	exit 1
fi

workfolder=$(pwd)
ifile='pp_manual'
release_dir=`cat conf/ar.conf | grep 'rls_root_dir' | awk -F'=' '{print $2}' | sed -e "s/.*'\(.*\)'.*/\1/"`
release_dir="${release_dir}/${ver}/manual/"
publish_dir=`cat conf/ar.conf | grep 'pul_root_dir' | awk -F'=' '{print $2}' | sed -e "s/.*'\(.*\)'.*/\1/"`
publish_dir=$publish_dir'/'${ver}'/manual/'
tmp_dir='/tmp/a2pf-release/'${ver}'/manual/'

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

rm -rf ${tmp_dir}
mkdir -p ${tmp_dir}

for line in `awk -F: '{print $2 "/" $3}' ${ifile}`; do
	filename=$(basename $line)
	cp -r "$line" "${tmp_dir}"
done

err=0
for pysrc in `ls ${tmp_dir} | grep '\.py$'`; do
	if [ -f "${tmp_dir}/${pysrc}" ]; then
		echo "pylint ${pysrc}"
		`cd ${tmp_dir}; \
			pylint --rcfile=${workfolder}/conf/pylint.conf -E ${pysrc} \
			> ${workfolder}/pylt.log 2>&1`

		if [ $(wc -l pylt.log | awk '{print $1}') -ne '0' ]; then
			err=1
			echo "	ERROR - pylint found error in <${pysrc}>"
			cat pylt.log | sed 's/^/\t/'
		fi
	fi
done

rm pylt.log
if [ $err != 0 ]; then
	exit 1
fi

tar_file="${tmp_dir}../manual.tar.bz2"
rm -rf "${tar_file}"
echo "tar manual"
tar -C "${tmp_dir}/../" -jcvf "${tar_file}" manual
cp "${tar_file}" "${release_dir}"
sudo cp "$tar_file" "${publish_dir}"

rm -rf ${ifile}
