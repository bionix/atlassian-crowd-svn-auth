#!/bin/bash

set -e

# install some needed packages
sudo aptitude -y install autoconf libtool apache2-threaded-dev libsvn-dev libcurl4-gnutls-dev libxml2-dev

# prepare working dir
case "$0" in
  /* ) SCRIPT_DIR="$0" ;;
  ./* ) SCRIPT_DIR="$PWD/${0#./}" ;;
  */* ) SCRIPT_DIR="$PWD/$0" ;;
  * ) echo "Unkown Error"; exit 1 ;;
esac

WORKING_DIR=${SCRIPT_DIR%/*}/../src

if [ ! -d $WORKING_DIR ]; then
  mkdir $WORKING_DIR
fi

cd $WORKING_DIR

# determine lates version
SVN_BASE="https://studio.plugins.atlassian.com/svn/CWDAPACHE/tags/"
VERSION=$(svn list $SVN_BASE | tail -1)
# remove trailing slash
VERSION=${VERSION%/*}


if [ -d "$VERSION" ]; then
  # version exists - clean up
  cd $VERSION
  make clean
else
  # download and configure new version
  svn export "$SVN_BASE$VERSION" $VERSION
  cd $VERSION
  autoreconf --install 
  ./configure
fi
 
# finally make
make

# prepare packages
WORKING_DIR=$WORKING_DIR/../packages
if [ -d $WORKING_DIR ]; then
  sudo rm -Rf $WORKING_DIR
fi 
mkdir $WORKING_DIR
cd $WORKING_DIR

cp -R ../skeleton/libapache2-mod-auth-crowd .
cp -R ../skeleton/libapache2-mod-auth-crowd-svn .
sed -i "s/VERSION/$VERSION/" libapache2-mod-auth-crowd/DEBIAN/control
sed -i "s/VERSION/$VERSION/" libapache2-mod-auth-crowd-svn/DEBIAN/control

cp ../src/$VERSION/src/.libs/mod_authnz_crowd.so libapache2-mod-auth-crowd/usr/lib/apache2/modules
cp ../src/$VERSION/src/svn/.libs/mod_authz_svn_crowd.so libapache2-mod-auth-crowd-svn/usr/lib/apache2/modules

sudo chown -R root:root *
sudo chmod 0755 libapache2-mod-auth-crowd/DEBIAN/postinst
sudo chmod 0755 libapache2-mod-auth-crowd/DEBIAN/prerm
sudo chmod 0755 libapache2-mod-auth-crowd-svn/DEBIAN/postinst
sudo chmod 0755 libapache2-mod-auth-crowd-svn/DEBIAN/prerm

# build the packages
sudo dpkg -b libapache2-mod-auth-crowd libapache2-mod-auth-crowd-$VERSION-amd64.deb
sudo dpkg -b libapache2-mod-auth-crowd-svn libapache2-mod-auth-crowd-svn-$VERSION-amd64.deb
