#!/bin/bash

if [[ -f ${HOME}/.ragnar.rc ]]; then
    source ${HOME}/.ragnar.rc
else
    TOP=${TOP:-"${HOME}"}
fi
TOP=${TOP}/tb-artifacts
mkdir -p ${TOP}

usage() {
	echo -e "$0's help text"
	echo -e "   -b BRANCH, branch from the kernel repository."
	echo -e "   -f FILE, yaml file to build from."
	echo -e "   -g GIT_REPOSITORY, kernel repository to build,"
	echo -e "   -l \"list of files\", that should be downloaded,"
	echo -e "      default: config, kernel and modules"
	echo -e "   -r if you only want to download config and build.log"
	echo -e "      to be able to reproduce a randconfig build."
}

download_file() {
	path_and_file=${1}
	echo curl -sSOL ${path_and_file}
	curl -sSOL ${path_and_file}
}

remove_quotes() {
	echo $(echo ${1}|sed 's|"||g')
}

download_files() {
	local url=${1}
	local file_list=${2}
	url=$(remove_quotes ${url})
	echo ${url}
	builddir=$(echo ${url}| awk -F '/' '{print $(NF-1)}')
	mkdir -p ${OUTPUTDIR}/${builddir}
	cd ${OUTPUTDIR}/${builddir}
	download_file "${url}bmeta.json"
	echo file_list: ${file_list}
	for file in $(echo ${file_list}); do
		echo ${file}
		echo download_file "${url}${file}"
		download_file "${url}${file}"
	done
	if [[ ${RANDCONFIG} -eq 1 ]]; then
		sed '/KCONFIG_SEED=/,$!d' build.log |sed '/^scripts/,$d'|grep -v "cd /linux">build_configuration.conf
	else
		download_file "${url}$(remove_quotes $(cat bmeta.json| jq '.kernel_image'))"
		download_file "${url}$(remove_quotes $(cat bmeta.json| jq '.modules'))"
	fi
	cd -
	echo ${OUTPUTDIR}/${builddir}
}

DEFAULT_FILE_LIST="build.log kernel.config"
RANDCONFIG=0

while getopts "b:f:g:hl:r" arg; do
	case $arg in
		b)
			BRANCH="$OPTARG"
			;;
		f)
			FILE="$OPTARG"
			;;
		g)
			GIT_REPOSITORY="$OPTARG"
			;;
		l)
			INPUT_FILE_LIST="$OPTARG"
			;;
		r)
			RANDCONFIG=1
			;;
		h|*)
			usage
			exit 0
			;;
	esac
done

GIT_REPOSITORY=${GIT_REPOSITORY:-"https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git"}

if [[ -z ${BRANCH} ]]; then
	echo "ERROR: forgot to set branch!"
	usage
	exit 0
fi

if [[ -z ${FILE} ]]; then
	echo "ERROR: forgot to set file!"
	usage
	exit 0
fi

OUTPUTDIR=${TOP}/$(date +"%Y%m%d-%H%m")
mkdir -p ${OUTPUTDIR}
tb_json_artifact="${OUTPUTDIR}/build-artifact.json"
logfilename=$(echo $(basename ${FILE})|awk -F. '{print $1}').log
echo tuxbuild build-set --git-repo ${GIT_REPOSITORY} --git-sha ${BRANCH} --tux-config ${FILE} --set-name basic --json-out ${tb_json_artifact} | tee ${OUTPUTDIR}/${logfilename}
tuxbuild build-set --git-repo ${GIT_REPOSITORY} --git-ref ${BRANCH} --tux-config ${FILE} --set-name basic --json-out ${tb_json_artifact} 2>&1 | tee -a ${OUTPUTDIR}/${logfilename}

if [[ ${RANDCONFIG} -eq 1 ]]; then
	file_list="${DEFAULT_FILE_LIST}"
	for url in $(cat ${tb_json_artifact}| jq '.[] | select(.warnings_count != 0) | .download_url'); do
		download_files "${url}" "${file_list}"
	done
else
	file_list="${DEFAULT_FILE_LIST} ${INPUT_FILE_LIST}"
	for url in $(cat ${tb_json_artifact}| jq '.[] | .download_url'); do
		download_files "${url}" "${file_list}"
	done
fi
