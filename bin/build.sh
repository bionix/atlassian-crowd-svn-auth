#!/bin/bash

set -e

if [[ $UID -ne 0 ]]; then
    echo "$0 must be run as root"
    exit 1
fi



# install some needed packages
apt-get -y install autoconf git-core libtool apache2-threaded-dev libsvn-dev build-essential devscripts libcurl4-gnutls-dev libxml2-dev

# prepare working dir
case "$0" in
  /* ) SCRIPT_DIR="$0" ;;
  ./* ) SCRIPT_DIR="$PWD/${0#./}" ;;
  */* ) SCRIPT_DIR="$PWD/$0" ;;
  * ) echo "Unkown Error"; exit 1 ;;
esac

ROOT_DIR="$PWD"

cd ../src
WORKING_DIR="$PWD"

if [ ! -d $WORKING_DIR ]; then
  mkdir $WORKING_DIR
fi

git clone https://bitbucket.org/atlassian/cwdapache.git $WORKING_DIR

cd $WORKING_DIR
echo "WORKING_DIR :  $WORKING_DIR"

GITTAG_VERSION=`(git tag | sort -n | tail -1)`

aclocal
libtoolize
autoreconf --install
  ./configure
# finally make
make
cd $ROOT_DIR ; cd .. ;

# prepare packages
WORKING_DIR=$PWD/packages
if [ -d $WORKING_DIR ]; then
  rm -Rf $WORKING_DIR
fi
mkdir $WORKING_DIR
cd $WORKING_DIR

cp -R ../skeleton/libapache2-mod-auth-crowd .
cp -R ../skeleton/libapache2-mod-auth-crowd-svn .
sed -i "s/VERSION/$GITTAG_VERSION/" libapache2-mod-auth-crowd/DEBIAN/control
sed -i "s/VERSION/$GITTAG_VERSION/" libapache2-mod-auth-crowd-svn/DEBIAN/control

mkdir -p libapache2-mod-auth-crowd/usr/lib/apache2/modules
cp ../src/src/.libs/mod_authnz_crowd.so libapache2-mod-auth-crowd/usr/lib/apache2/modules
mkdir -p libapache2-mod-auth-crowd-svn/usr/lib/apache2/modules
cp ../src/src/svn/.libs/mod_authz_svn_crowd.so libapache2-mod-auth-crowd-svn/usr/lib/apache2/modules

 chown -R root:root *
 chmod 0755 libapache2-mod-auth-crowd/DEBIAN/postinst
 chmod 0755 libapache2-mod-auth-crowd/DEBIAN/prerm
 chmod 0755 libapache2-mod-auth-crowd-svn/DEBIAN/postinst
 chmod 0755 libapache2-mod-auth-crowd-svn/DEBIAN/prerm

# build the packages
 dpkg -b libapache2-mod-auth-crowd libapache2-mod-auth-crowd-$GITTAG_VERSION-amd64.deb
 dpkg -b libapache2-mod-auth-crowd-svn libapache2-mod-auth-crowd-svn-$GITTAG_VERSION-amd64.deb
