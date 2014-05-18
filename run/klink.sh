#! /bin/sh
#
# klink.sh
#
# Run the test suite in Klink.
#
# Preparation:
#
#   1) download Klink from the git repository http://repo.or.cz/w/Klink.git
#   2) optionally apply klink.patch, if at commit 7c8a173...
#   3) make
#   4) fix KPATH in this script
#

KPATH=~/src/kernel/Klink
KLINK=klink

if [ ! -d $KPATH -o ! -x $KPATH/klink -o ! -f $KPATH/init.krn ] ; then
    echo "Klink not found in $KPATH, check paths in run/klink.sh." 1>&2
    exit 1
fi

ln -s $KPATH/init.krn tests/init.krn
ln -s $KPATH/klink tests/klink
cd tests
./klink -1 ../run/klink-compatibility.k
