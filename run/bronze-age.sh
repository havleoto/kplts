#! /bin/sh
#
# bronze-age.sh
#
# Run the test suite in Bronze Age Lisp.
#
# Preparation:
#
#  1) download & compile Bronze Age Lisp from
#
#     https://bitbucket.org/havleoto/bronze-age-lisp
#
#  2) add Bronze Age Lisp executable to PATH
#

cd tests
bronze-devel \
  -l ../run/parse-options.k -l ../run/bronze-age-compatibility.k \
  -l ../support/utils.k -l ../support/random.k \
  -l ../support/checks.k -l ../support/fuzz.k \
  -l ../support/hierarchy.k \
  suite.k "$@"
