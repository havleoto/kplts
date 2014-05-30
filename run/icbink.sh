#! /bin/sh

#ICBINK=~/src/kernel/icbink/entry_point-c

# Allow user to set their own.
if [ -z $ICBINK ] ; then
    ICBINK=~/klisp/icbink/entry_point-c
fi

cd $(dirname $0)/../tests
$ICBINK ../run/icbink-compatibility.k
