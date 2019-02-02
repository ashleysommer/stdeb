#!/bin/bash
PYTHON_PROJECT_GIT="${PYTHON_PROJECT_GIT:-https://github.com/ashleysommer/stdeb3.git}"
PYTHON_PROJECT_BRANCH="${PYTHON_PROJECT_BRANCH:-master}"
OUT_DIR="/home/stdeb3/output"

HAS_GPG2="$(which gpg2)"
if [ "$?" = "0" ]; then
  GPG="$HAS_GPG2"
else
  GPG="$(which gpg)"
fi


source /etc/os-release
if [ -z "${ID}" -o -z "${VERSION_ID}" ]; then
  echo "/etc/os-release does not provide \$ID or \$VERSION_ID. Using fallbacks."
  cat /etc/os-release
  if [ -z "${VERSION_CODENAME}" ]; then
      MY_SUFFIX="unknown"
  else
      MY_SUFFIX="${VERSION_CODENAME}"
  fi
else
  MY_SUFFIX="${ID}-${VERSION_ID}"
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
git submodule foreach "git pull"

if [ -z "${GPG_SECRET_KEY}" ]; then
  echo "No secret keys given."
  CAN_SIGN=""
else
  if [ -e ${GPG_SECRET_KEY} -a -f ${GPG_SECRET_KEY} ]; then
    echo "using gpg secret key file: ${GPG_SECRET_KEY}"
    GPG_IMPORT_COMMAND="--allow-secret-key-import -a --import $GPG_SECRET_KEY"
  else
	echo "using gpg secret key string: [hidden]"
	USE_SECRET_KEY=$(echo "${GPG_SECRET_KEY}" | sed 's|\\n|\n|g')
	GPG_IMPORT_COMMAND="--allow-secret-key-import -a --import <(echo "${USE_SECRET_KEY}")"
  fi

  if [ -z "${GPG_SECRET_KEY_PASSPHRASE}" ]; then
    echo "No secret key passphrase given."
  else
    gpgconf --kill gpg-agent
    echo "#!/bin/bash" > /tmp/signproxy
    if [ -e ${GPG_SECRET_KEY_PASSPHRASE} -a -f ${GPG_SECRET_KEY_PASSPHRASE} ]; then
      echo "using gpg secret key passphrase file: ${GPG_SECRET_KEY_PASSPHRASE}"
      echo "${GPG} --batch --yes --no-tty --pinentry-mode loopback --no-use-agent --passphrase-file ${GPG_SECRET_KEY_PASSPHRASE} \"\$@\"" >> /tmp/signproxy
    else
      echo "using gpg secret key passphrase: [hidden]"
      echo "${GPG} --batch --yes --no-tty --pinentry-mode loopback --no-use-agent --passphrase ${GPG_SECRET_KEY_PASSPHRASE} \"\$@\"" >> /tmp/signproxy
    fi
    #cat /tmp/signproxy
    chmod a+x /tmp/signproxy
    GPG="/tmp/signproxy"
  fi
  GPG_IMPORT_COMMAND="${GPG} ${GPG_IMPORT_COMMAND}"
  eval "${GPG_IMPORT_COMMAND}"
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
      SIGN_RESULTS="--sign-results --gpg-proxy=${GPG}"
      DPKG_SIGN_ARG="--sign-command=${GPG}"
  fi
fi

if [ -z "${STDEB3_SIGN_KEY}" ]; then
  echo ""
else
  SIGN_RESULTS="${SIGN_RESULTS} --sign-key=\"${STDEB3_SIGN_KEY}\""
  DPKG_SIGN_ARG="${DPKG_SIGN_ARG} --sign-key=\"${STDEB3_SIGN_KEY}\""
fi


if [ -z "${STDEB3_EXTRA_ARGS}" ]; then
  EXTRA_ARGS=""
else
  EXTRA_ARGS="${STDEB3_EXTRA_ARGS}"
fi


echo "Running python3 ./setup.py --command-packages=stdeb3.command sdist_dsc ${SIGN_RESULTS} ${EXTRA_ARGS}"
python3 ./setup.py --command-packages=stdeb3.command sdist_dsc ${SIGN_RESULTS} ${EXTRA_ARGS}

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



PKG_COMMAND="dpkg-buildpackage -rfakeroot -b ${DPKG_SIGN_ARG}"
eval "${PKG_COMMAND}"


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
cp -f "${DEB_FILE}" "${OUT_DIR}/${DEB_FILE_NAME}+${MY_SUFFIX}.deb"

BUILT_FILES=$(find -mindepth 1 -maxdepth 1 -type f -iname "${BUILT_PROJ_NAME}*" | sed 's|^\./||')
read -rd '' -a BUILT_FILES_A <<<"${BUILT_FILES}"
for BUILT_FILE in ${BUILT_FILES_A[@]}; do
    cp -f "${BUILT_FILE}" "${OUT_DIR}/"
done
ls -lah "${OUT_DIR}"

IFS=$OLDIFS
exit 0
