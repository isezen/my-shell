#!/bin/bash
# 2016-03-27
# sezenismail@gmail.com
# sh -c "$(curl -sL https://git.io/vVftO)"
# Install my shell settings and aliases.
#

function die() {
  echo "${1}"
  exit 1
}

function save() {
  local fnamebase="$1"
  local fname="${HOME}/.$fnamebase.${SHELL}"
  local relfname="${HOME_PREFIX}/.$fnamebase.${SHELL}"
  local url="$2"
  echo "Downloading script from ${url} and saving it to ${fname}..."
  curl -sL "${url}" > "${fname}" || die "Couldn't download script from ${url}"
  chmod +x "${fname}"
  echo "Checking if ${SCRIPT} contains $fnamebase..."
  grep "$fnamebase" "${SCRIPT}" > /dev/null 2>&1 || (echo "Appending source command to ${SCRIPT}..."; echo "" >> "${SCRIPT}"; echo "test -e ${QUOTE}${relfname}${QUOTE} ${SHELL_AND} source ${QUOTE}${relfname}${QUOTE}" >> "${SCRIPT}")
  echo "Done."
  echo ""
}

SHELL=$(echo "${SHELL}" | tr / "\n" | tail -1)
# shellcheck disable=SC2016
HOME_PREFIX='${HOME}'
SHELL_AND='&&'
QUOTE=''
if [ "${SHELL}" == bash ];then
  URL1="https://raw.githubusercontent.com/isezen/my-shell/master/alias.sh"
  URL2="https://raw.githubusercontent.com/isezen/my-shell/master/bash.sh"
  test -f "${HOME}/.bash_profile" && SCRIPT="${HOME}/.bash_profile" || SCRIPT="${HOME}/.profile"
  QUOTE='"'
elif [ "${SHELL}" == fish ];then
  echo "Make sure you have fish 2.2 or later. Your version is:"
  fish -v

  URL1="https://raw.githubusercontent.com/isezen/my-shell/master/alias.fish"
  URL2="https://raw.githubusercontent.com/isezen/my-shell/master/bash.fish"
  mkdir -p "${HOME}/.config/fish"
  SCRIPT="${HOME}/.config/fish/config.fish"
  HOME_PREFIX='{$HOME}'
  SHELL_AND='; and'
else
  die "Your shell, ${SHELL}, is not supported yet. Only bash are supported. Sorry!"
  exit 1
fi

save myaliases "$URL1"
save mybash "$URL2"

echo "The next time you log in, shell settings will be enabled."
