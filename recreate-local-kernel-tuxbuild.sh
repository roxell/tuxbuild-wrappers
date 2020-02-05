#!/bin/bash

if [[ -f ${HOME}/.ragnar.rc ]]; then
	source ${HOME}/.ragnar.rc
else
	TOP=${TOP:-"${HOME}"}
fi
TOP=${TOP}/tb-artifacts

mypwd=$(pwd)

usage() {
	echo -e "$(basename $0)'s help text"
	echo -e "   -f file to build, if not provided we will build the Image file"
}

set_config_file() {
	cd $obj_dir
	echo ../scripts/kconfig/merge_config.sh -m ${1}
	../scripts/kconfig/merge_config.sh -m ${1}
	cd -
}

set_config_frag() {
	cd $obj_dir
	echo ../scripts/config --enable ${1}
	../scripts/config --enable ${1}
	cd -
}

find_artifact_builds() {
	pushd ${TOP}/ > /dev/null 2>&1
	tmp=$(find . -maxdepth 2 -type d|sed 's|^./||g'|awk -F/ '$2'|sort)
	echo $tmp|tr " " "\n"|sed 's|^|  |'
	popd > /dev/null 2>&1
}

find_file () {
	pushd ${TOP}/ > /dev/null 2>&1
	file_path=$(grep ": warning: " ${1} |sed -e 's|\.\.\/||g'|awk -F':' '{print $1}')
	echo ${file_path}|tr " " "\n" |sed 's|^|  |'
	popd > /dev/null 2>&1
}

while getopts "f:h" arg; do
	case $arg in
		f)
			stuff_to_build="$OPTARG"
			;;
		h|*)
			usage
			exit 0
			;;
	esac
done

if [[ -z $list_staging ]]; then
	echo "Listing artifact builds that reported a warning(s):"
	find_artifact_builds
	num_builds=$(find_artifact_builds|wc -l)
	if [[ $num_builds -eq 0 ]]; then
		exit 0
	elif [[ $num_builds -eq 1 ]]; then
		artifact_buildstr=$(find_artifact_builds | sed 's/ //g')
	else
		echo
		echo "Copy/paste what artifact build dir you want to"
		echo "build, followed by [ENTER]:"
		read artifact_buildstr
	fi
fi

cd ${mypwd}

source ${TOP}/${artifact_buildstr}/build_configuration.conf

if [[ -z $stuff_to_build ]]; then
	echo "Listing files that contains warning(s):"
	find_file ${artifact_buildstr}/build.log
	num_builds=$(find_file ${artifact_buildstr}/build.log|wc -l)
	if [[ $num_builds -eq 0 ]]; then
		exit 0
	elif [[ $num_builds -eq 1 ]]; then
		stuff_to_build=$(find_file ${artifact_buildstr}/build.log | sed 's/ //g')
	else
		echo
		echo "Copy/paste the file you want to"
		echo "build, followed by [ENTER]:"
		read stuff_to_build
	fi
	stuff_to_build=$(echo ${stuff_to_build} |awk -F. '{print $1}').o
fi


obj_dir="obj-randconfig-${ARCH}-$(git describe|awk -F'-' '{print $1"-"$2}')"

if [[ -z ${CROSS_COMPILE} ]]; then
	cross_build=""
else
	cross_build="CROSS_COMPILE=${CROSS_COMPILE}"
fi


echo make ARCH=${ARCH} HOSTCC=${HOSTCC} -skj$(getconf _NPROCESSORS_ONLN) O=${obj_dir} ${cross_build} defconfig
make ARCH=${ARCH} HOSTCC=${HOSTCC} -skj$(getconf _NPROCESSORS_ONLN) O=${obj_dir} ${cross_build} defconfig
cp ${TOP}/${artifact_buildstr}/kernel.config ${obj_dir}/.config
echo make ARCH=${ARCH} HOSTCC=${HOSTCC} -skj$(getconf _NPROCESSORS_ONLN) O=${obj_dir} ${cross_build} olddefconfig
make ARCH=${ARCH} HOSTCC=${HOSTCC} -skj$(getconf _NPROCESSORS_ONLN) O=${obj_dir} ${cross_build} olddefconfig

echo
echo "building ${obj_dir}"
echo
echo make ARCH=${ARCH} HOSTCC=${HOSTCC} -skj$(getconf _NPROCESSORS_ONLN) O=${obj_dir} ${cross_build} INSTALL_MOD_PATH=${obj_dir}/modules_install ${stuff_to_build}
make ARCH=${ARCH} HOSTCC=${HOSTCC} -skj$(getconf _NPROCESSORS_ONLN) O=${obj_dir} ${cross_build} INSTALL_MOD_PATH=${obj_dir}/modules_install ${stuff_to_build}
cd -
