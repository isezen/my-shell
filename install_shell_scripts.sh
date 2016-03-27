#!/bin/bash
# 2016-03-27
# sezenismail@gmail.com
# sudo sh -c "$(curl -sL https://git.io/vVfYB)"
# Install my shell scripts
#

function die() {
  echo "${1}"
  exit 1
}

function save() {
  local fbase="$1"
  local fname="${_PREFIX}/$fbase"
  local url="$_URLM/$fbase"
  echo "Downloading script from ${url} and saving it to ${fname}..."
  curl -sL "${url}" > "${fname}" || die "Couldn't download script from ${url}"
  chmod +x "${fname}"
  echo "Done."
  echo ""
}

SHELL=$(echo "${SHELL}" | tr / "\n" | tail -1)
# shellcheck disable=SC2016
_PREFIX='/usr/local/bin'
_URLM="https://raw.githubusercontent.com/isezen/my-shell/master/scripts"
QUOTE=''
if [ "${SHELL}" == bash ]; then
  test -f "${HOME}/.bash_profile" && SCRIPT="${HOME}/.bash_profile" || SCRIPT="${HOME}/.profile"
  QUOTE='"'
else
  die "Your shell, ${SHELL}, is not supported yet. Only bash are supported. Sorry!"
  exit 1
fi

mkdir -p "$_PREFIX"
echo "Checking if PATH contains ${_PREFIX}..."
if [[ ":$PATH:" != *":$_PREFIX:"* ]]; then
  grep "$_PREFIX" "${SCRIPT}" > /dev/null 2>&1 || (echo "Appending export command to ${SCRIPT}..."; echo "" >> "${SCRIPT}"; echo "export PATH=\"$_PREFIX:$PATH\"" >> "${SCRIPT}")
  echo "Done."
fi
echo ""
for s in ll dus dusf dusf.; do save "$s"; done

echo "The next time you log in, shell scripts will be enabled."
