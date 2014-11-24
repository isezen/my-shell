#!/bin/bash
# sezenismail@gmail.com
# 2014-11-23
#

# SETTINGS
APPNAME="mybash"
FILES_TO_COPY="mybash.bashrc bash_aliases.bashrc"
INSTALLDIR="mybash"


# Global Variables
INSTALLATION_DIR=
SOURCE_SCRIPT=
BASHRC_FILE=

_set_globals() {
  _myos=`uname`
  [[ $ALLUSERS = 1 ]] && prefix="/etc" || prefix="$HOME" # Install to /etc or $HOME.
  [[ $ALLUSERS = 1 ]] && dirname="/$INSTALLDIR" || dirname="/.$INSTALLDIR" # Use hidden folder for private installation
  INSTALLATION_DIR="$prefix$dirname"
  SOURCE_SCRIPT='. '$INSTALLATION_DIR'/mybash.bashrc'
  #
  if [[ "$_myos" == 'Darwin' ]]; then # Set bashrc file name
    [[ $ALLUSERS = 1 ]] && BASHRC_FILE=$prefix'/bashrc' || BASHRC_FILE=$prefix'/.bashrc'
  else # Linux (for Ubuntu)
    [[ $ALLUSERS = 1 ]] && BASHRC_FILE=$prefix'/bash.bashrc' || BASHRC_FILE=$prefix'/.bashrc'
  fi
}

_install() {
  echo "Installing $APPNAME"
  # Check bashrc file existance
  if [ ! -f "$BASHRC_FILE" ]; then echo "$BASHRC_FILE can not be found. Stopping...";exit 1;fi
  #
  # Copy required Files
  mkdir -p $INSTALLATION_DIR # Create directory
  cp $FILES_TO_COPY $INSTALLATION_DIR
  # cp "mybash.bashrc" $INSTALLATION_DIR
  # cp "bash_aliases.bashrc" $INSTALLATION_DIR

  echo "Created $INSTALLATION_DIR"

  # If file is not patched before
  if ! grep -q "$SOURCE_SCRIPT" "$BASHRC_FILE"; then
    cp $BASHRC_FILE $BASHRC_FILE'.backup' # create backup
    echo "$BASHRC_FILE backed up as $BASHRC_FILE.backup"
    echo $SOURCE_SCRIPT >> $BASHRC_FILE # Patch the file
    echo "$BASHRC_FILE patched."
  fi
  #
  exit 0
}

_uninstall() {
  echo "Uninstalling $APPNAME"
  # Check bashrc file existance
  if [ ! -f "$BASHRC_FILE" ]; then echo "$BASHRC_FILE can not be found. Stopping...";exit 1;fi
  # If file is patched before
  if grep -q "$SOURCE_SCRIPT" "$BASHRC_FILE"; then
    # sed -i '/'"$SOURCE_SCRIPT"'/d' $BASHRC_FILE # remove patched line
    remove_string=$(echo "$INSTALLATION_DIR/mybash.bashrc" | sed -e 's/[\/&]/\\&/g')
    # remove_string="/[\/&]$INSTALLATION_DIR/mybash.bashrc/d"
    echo $remove_string
    sed -i '/'$remove_string'/d' $BASHRC_FILE
    echo "Removed patch from $BASHRC_FILE"
  fi
  rm -rf "$INSTALLATION_DIR"
  echo "$APPNAME Uninstalled succesfully."
}

_usage() {
  echo "Mybash script 2014 Ismail SEZEN"
  echo "Usage: $0 -avh"
  echo "-a |--all-users : Install for all users in '/etc' folder."
  echo "                  (Requires 'sudo' or 'su' privileges)"
  echo "-v |--verbose   : Verbose output."
  echo "-h |--help      : Shows this message."
  exit 1
}

_get_OS() {
  _myos=`uname`
  if [[ "$_myos" == 'Linux' ]]; then
    _distro=$(lsb_release -si)
  elif [[ "$_myos" == 'Darwin' ]]; then
    _distro=$OSTYPE
  fi
  echo "$_distro"
}

#####################################################################
# A POSIX variable
OPTIND=1 # Reset in case getopts has been used previously in the shell.

VERBOSE=0

echo "OS : $(_get_OS)"
while getopts "h?vau" opt; do
  case "$opt" in
    h|\?)
    _usage
    exit 0
    ;;
    v)  VERBOSE=1
    ;;
    a)  ALLUSERS=1
    ;;
    u)  UNINSTALL=1
    ;;
  esac
done
shift $((OPTIND-1))

[ -z ${ALLUSERS+x} ] && ALLUSERS=0 # If ALLUSERS is not set, Set it to 0.
[[ $ALLUSERS = 1 ]] && txtinstype="for ALL USERS" || txtinstype="ONLY for YOU"
question="";
[ -z ${UNINSTALL+x} ] && _str_install="install" || _str_install="uninstall"
question=$(printf "This script will $_str_install 'mybash' %s. Do you want to continue\\?" "$txtinstype")
[[ $ALLUSERS = 0 ]] && question=$question"\nYou can use -a flag install for all users."
question=$question"\n[Y]es/[N]o? ";
printf "$question";
while true; do
  read yn
  case $yn in
    [Yy]* ) break;;
    [Nn]* ) echo "Nothing was installed.";exit;;
    * ) printf "Please answer Y or N. ";;
  esac
done
echo $UNINSTALL

_set_globals;
if [ -z ${UNINSTALL+x} ]; then
  _install;
else
  _uninstall;
fi

exit 0;
