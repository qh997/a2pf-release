#!/bin/bash -ex

WORKDIR=$(cd `dirname $0`; pwd)
cd $WORKDIR

function init {
	ARGS=$(getopt -o pc --long prepare --long commit --long compile: -n "$0" -- "$@")
	eval set -- "$ARGS"
	while true ; do
		case "$1" in
			-p|--prepare) : ${prepare:=1}; shift;;
			-c|--commit) : ${commit:=1}; shift;;
			--compile) compile=$2; shift 2;;
			--) shift; break;;
			*) echo "Internal error."; exit 1;;
		esac
	done

	: ${compile:='true'}
}

init $@

svn_dir=`cat conf/ar.conf | grep 'rls_root_dir' | awk -F'=' '{print $2}' | sed -e "s/.*'\(.*\)'.*/\1/"`

tag=`cat conf/daily.conf | grep 'base-tag' | awk -F'=' '{print $2}' | sed -e "s/^ +//" | sed -e "s/ +$//"`
if [ -z $tag ]; then
	tag=`svn ls --username gengs --password 'qh997@NEU3' \
		'http://10.1.42.140/svn/apf_apn_ten_svn_src/arm/tags/' \
		| sort -r | sed -n '1p' | sed 's/\/$//'`
fi
echo "Daily build base on '$tag'"

ver=`svn ls --username gengs --password 'qh997@NEU3' \
	'http://10.1.42.140/svn/ADA/02%20DevelopLibrary/05.A2PF_ST/04.Coding/01.Functional/03.Release/' \
	| sort -r | sed -n '1p' | sed 's/\/$//'`

if [ `echo $ver | grep '[0-9]*\.[0-9]*'` ]; then
	sub_ver=$(echo $ver | sed 's/^[0-9]*\.//')
	ver=$(echo $ver | sed 's/\.[0-9]*$//')
else
	sub_ver=000
fi
echo "Main version is '$ver'"

export DAILY_BUILD=true
if [ "$prepare" = "1" ]; then
	./clean
	./svn-sweep $svn_dir
	sub_ver=`printf '%03d' $((++sub_ver))`
	sub_ver="${ver}.${sub_ver}"
	echo "Prepare for release '$sub_ver'"

	rm -rf "${svn_dir}/$sub_ver"
	mkdir -p "${svn_dir}/$sub_ver"
	cp -r "${svn_dir}/${ver}/doc/" "${svn_dir}/$sub_ver/"

	./svn-arrange "${svn_dir}/$sub_ver/"
	echo "svn commit -m \"Release for ${sub_ver} on <${tag}>.\" --username 'gengs' --password '***' \"${svn_dir}\""
	set -v
	svn commit -m "Release for ${sub_ver} on <${tag}>." --username 'gengs' --password 'qh997@NEU3' "${svn_dir}"
	set +v
elif [ "$commit" = "1" ]; then
	sub_ver="${ver}.${sub_ver}"
	echo "Commit for release '$sub_ver'"

	./commit-all.sh ${tag} ${sub_ver} 'COMMIT' true true true true true # <Commit All>
else
	./clean
	./svn-sweep $svn_dir
	sub_ver="${ver}.${sub_ver}"
	echo "Daily build for '${sub_ver}'"
	./make-android.sh ${tag} ${sub_ver} ${compile} # <Android Make>
	./release-all.sh ${tag} ${sub_ver} true true true true true # <Release All>
	./tag-all.sh ${tag} ${sub_ver} true true true true true # <Tag All>

	sudo mail-maker.pl -s daily-compile-success -f VERSION=$sub_ver MAIN-VERSION="${tag}"
fi
