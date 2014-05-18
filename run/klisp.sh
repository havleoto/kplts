#! /bin/sh
#
# klisp.sh
#
# Run the test suite in klisp.
#
# Preparation:
#
#  1) download & compile klisp from
#
#     https://bitbucket.org/AndresNavarro/klisp
#
#  2) add klisp executable to PATH
#

cd tests
klisp \
  -l ../run/klisp-compatibility.k \
  -l ../support/utils.k -l ../support/random.k \
  -l ../support/checks.k -l ../support/hierarchy.k \
  suite.k
