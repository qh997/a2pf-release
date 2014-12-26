#!/bin/bash

# pylint --generate-rcfile > pylint.conf

ver=$1

workfolder=$(pwd)
ifile='pp_case'
publish_dir=`cat conf/ar.conf | grep 'rls_root_dir' | awk -F'=' '{print $2}' | sed -e "s/.*'\(.*\)'.*/\1/"`
publish_dir="${publish_dir}/${ver}/testcase/"
comm_dir="/home/gengs/projects/prepare/${ver}/common"
tmp_dir='/tmp/a2pf-release/'${ver}'/testcase/'

if [ ! -e ${publish_dir} ]; then
	echo "ERROR - Cannot found ${publish_dir}."
	exit -1
fi

if [ ! -e ${ifile} ]; then
	echo "ERROR - Cannot found ${ifile}."
	exit -1
fi

rm -rf ${publish_dir}
mkdir -p ${publish_dir}
rm -rf ${tmp_dir}
mkdir -p ${tmp_dir}

err=0

for pysrc in `ls ${comm_dir} | grep '\.py$'`; do
	echo "pylint common/${pysrc}"
	`cd ${comm_dir}; \
		pylint --rcfile=${workfolder}/conf/pylint.conf -E ${pysrc} \
		> ${workfolder}/pylt.log 2>&1`

	if [ $(wc -l pylt.log | awk '{print $1}') -ne '0' ]; then
		err=1
		echo "	ERROR - pylint found error in <${dir}/${pysrc}>"
		cat pylt.log | sed 's/^/\t/'
	fi
done

rm pylt.log
if [ $err != 0 ]; then
	exit 1
fi

for line in `awk -F: '{print $2}' ${ifile}`; do
	filename=$(basename $line)
	cp -r "$line/" "${tmp_dir}"
done

for dir in `ls ${tmp_dir}`; do
	cp -r "${comm_dir}/" "${tmp_dir}/${dir}"
	mv "${tmp_dir}/${dir}/common/adb" "${tmp_dir}/${dir}"

	for pysrc in `ls ${tmp_dir}/${dir} | grep '\.py$'`; do
		if [ -f "${tmp_dir}/${dir}/${pysrc}" ]; then
			echo "pylint ${dir}/${pysrc}"
			`cd ${tmp_dir}/${dir}; \
				pylint --rcfile=${workfolder}/conf/pylint.conf -E ${pysrc} \
				> ${workfolder}/pylt.log 2>&1`

			if [ $(wc -l pylt.log | awk '{print $1}') -ne '0' ]; then
				err=1
				echo "	ERROR - pylint found error in <${dir}/${pysrc}>"
				cat pylt.log | sed 's/^/\t/'
			fi
		fi
	done
done

rm pylt.log
if [ $err != 0 ]; then
	exit 1
fi

for dir in `ls -F ${tmp_dir} | grep /$ | sed 's/\///'`; do
	tar_file="${tmp_dir}/${dir}.tar.bz2"
	rm -rf "${tar_file}"
	echo "tar ${dir}"
	tar -C ${tmp_dir} -jcvf "${tar_file}" ${dir}
	cp "${tar_file}" "${publish_dir}"
done

rm -rf ${ifile}
