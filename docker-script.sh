#!/bin/bash
PYTHON_PROJECT_GIT="${PYTHON_PROJECT_GIT:-https://github.com/ashleysommer/stdeb3.git}"
PYTHON_PROJECT_BRANCH="${PYTHON_PROJECT_BRANCH:-master}"
OUT_DIR="/home/stdeb3/output"

source /etc/os-release
if [ -z "${ID}" -o -z "${VERSION_ID}" ]; then
  echo "/etc/os-release does not provide \$ID or \$VERSION_ID. Using fallbacks."
  ID="debian"
  VERSION_ID="8"
else
  echo "Running on ${ID} ${VERSION_ID}"
fi
T1=$(touch "${OUT_DIR}/t1")
if [ "$?" -gt "0" ]; then
    echo "No permission to write to the bound output volume. Aborting."
    ls -lah ${OUT_DIR}
    exit 1
else
    rm -f "${OUT_DIR}/t1"
fi


echo "Using git project: $PYTHON_PROJECT_GIT"
git clone -b ${PYTHON_PROJECT_BRANCH} --recursive ${PYTHON_PROJECT_GIT} project
cd project
git submodule foreach "git checkout master"

if [ -z "${GPG_SECRET_KEY}" ]; then
  echo "No secret keys given."
  CAN_SIGN=""
else
  if [ -e ${GPG_SECRET_KEY} -a -f ${GPG_SECRET_KEY} ]; then
    echo "using gpg secret key file: ${GPG_SECRET_KEY}"
    gpg -v --allow-secret-key-import -a --import $GPG_SECRET_KEY
  else
	echo "using gpg secret key string: [hidden]"
	USE_SECRET_KEY=$(echo "${GPG_SECRET_KEY}" | sed 's|\\n|\n|g')
	gpg -v --allow-secret-key-import -a --import <(echo "${USE_SECRET_KEY}")
  fi
  CAN_SIGN="true"
fi

if [ -z "${STDEB3_SIGN_RESULTS}" -o "${STDEB3_SIGN_RESULTS}" = "0" ]; then
  SIGN_RESULTS=""
  DPKG_SIGN_ARG="-uc"
else
  if [ -z "${CAN_SIGN}" ]; then
      echo "--sign-results given, but no secret key given."
      SIGN_RESULTS=""
      DPKG_SIGN_ARG="-uc"
  else
      SIGN_RESULTS="--sign-results"
      DPKG_SIGN_ARG=""
  fi
fi

if [ -z "${STDEB3_SIGN_KEY}" ]; then
  SIGN_KEY=""
else
  SIGN_KEY="--sign-key=\"${STDEB3_SIGN_KEY}\""
fi


if [ -z "${STDEB3_EXTRA_ARGS}" ]; then
  EXTRA_ARGS=""
else
  EXTRA_ARGS="${STDEB3_EXTRA_ARGS}"
fi


echo "Running python3 ./setup.py --command-packages=stdeb3.command sdist_dsc ${SIGN_RESULTS} ${SIGN_KEY} ${EXTRA_ARGS}"
python3 ./setup.py --command-packages=stdeb3.command sdist_dsc ${SIGN_RESULTS} ${SIGN_KEY} ${EXTRA_ARGS}

if [ -d "./deb_dist" ]; then
  cd deb_dist
else
  echo "Error generating debian source tree"
  exit 1
fi

OLDIFS=$IFS
IFS=$'\n'
DSC_FILES=$(find -type f -iname '*.dsc' | sed 's|^\./||')
read -rd '' -a DSC_FILES_A <<<"${DSC_FILES}"
DSC_FILE="${DSC_FILES_A[0]}"
if [ -z "${DSC_FILE}" ]; then
  echo "Generated .dsc file not found!"
  exit 1
fi
echo "Generated .dsc file:"
cat "${DSC_FILE}"

if [ -z "${PRESERVE_OUTPUT_VOLUME}" -o "${PRESERVE_OUTPUT_VOLUME}" = "0" ]; then
  echo "Wiping any existing contents of output directory"
  rm -rf "${OUT_DIR}"/*
else
  echo "Preserving any existing contents of output directory"
fi

cp -f "${DSC_FILE}" "${OUT_DIR}/"

ORIG_TGZS=$(find -type f -iname '*.orig.tar.*' | sed 's|^\./||')
read -rd '' -a ORIG_TGZS_A <<<"${ORIG_TGZS}"
ORIG_TGZ="${ORIG_TGZS_A[0]}"
if [ -z "${ORIG_TGZ}" ]; then
  echo "The orig.tar.gz file not found!"
  exit 1
fi
cp -f "${ORIG_TGZ}" "${OUT_DIR}/"

DSC_FILE_LEN=${#DSC_FILE}
BUILT_PROJ_NAME_LEN=$(expr $DSC_FILE_LEN - 4)
BUILT_PROJ_NAME=${DSC_FILE:0:BUILT_PROJ_NAME_LEN}
echo "Build Project Name: ${BUILT_PROJ_NAME}"

if [ -z "${STDEB3_SOURCE_ONLY}" -o "${STDEB3_SOURCE_ONLY}" = "0" ]; then
  echo "Now building .deb package..."
else
  BUILT_FILES=$(find -mindepth 1 -maxdepth 1 -type f -iname "${BUILT_PROJ_NAME}*" | sed 's|^\./||')
  read -rd '' -a BUILT_FILES_A <<<"${BUILT_FILES}"
  for BUILT_FILE in ${BUILT_FILES_A[@]}; do
      cp -f "${BUILT_FILE}" "${OUT_DIR}/"
  done
  exit 0
fi

DSC_DIRECTORIES=$(find ! -path . -mindepth 1 -maxdepth 1 -type d ! -iname "tmp_*" | sed 's|^\./||')
read -rd '' -a DSC_DIRECTORIES_A <<<"${DSC_DIRECTORIES}"
DSC_DIR="${DSC_DIRECTORIES_A[0]}"
if [ -z "${DSC_DIR}" ]; then
  echo "Generated source tree directory not found!"
  exit 1
else
  echo "Entering ${DSC_DIR}"
  cd ${DSC_DIR}
fi

echo "Running dpkg-buildpackage -rfakeroot -b ${DPKG_SIGN_ARG} ${SIGN_KEY}"
dpkg-buildpackage -rfakeroot -b ${DPKG_SIGN_ARG} ${SIGN_KEY}

cd ..
ls -lah

DEB_FILES=$(find -mindepth 1 -maxdepth 1 -type f  -iname "*.deb" | sed 's|^\./||')
read -rd '' -a DEB_FILES_A <<<"${DEB_FILES}"
DEB_FILE="${DEB_FILES_A[0]}"
if [ -z "${DEB_FILE}" ]; then
  echo "Generated debian dist .deb file not found!"
  exit 1
fi
DEB_FILE_LEN=${#DEB_FILE}
DEB_FILE_NAME_LEN=$(expr $DEB_FILE_LEN - 4)
DEB_FILE_NAME=${DEB_FILE:0:DEB_FILE_NAME_LEN}
cp -f "${DEB_FILE}" "${OUT_DIR}/${DEB_FILE_NAME}+${ID}-${VERSION_ID}.deb"

BUILT_FILES=$(find -mindepth 1 -maxdepth 1 -type f -iname "${BUILT_PROJ_NAME}*" | sed 's|^\./||')
read -rd '' -a BUILT_FILES_A <<<"${BUILT_FILES}"
for BUILT_FILE in ${BUILT_FILES_A[@]}; do
    cp -f "${BUILT_FILE}" "${OUT_DIR}/"
done
ls -lah "${OUT_DIR}"

IFS=$OLDIFS
exit 0
