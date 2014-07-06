Run scripts
===========

  A run script is responsible for loading the test suite in its respective
  interpreter. The interpreter should load all *.k files in the "support"
  directory and then load suite.k in "tests." The directory "tests" is
  also the working directory of the run script.

  Before loading support/*.k, the dynamic environment should contain
  the following bindings:

  * test-print (applicative)

      (test-print EXPR EXPR ...)

      Print all EXPRs to the standard output, separated by spaces and
      followed by a new-line.

  * appropriate-number-of-calls (positive integer)

      The number of calls used in single tests. The number should be
      set according to the speed of the implementation (higher number
      for faster implementations). The implementation should be able
      to perform that many calls in less than one second.

  * supported-modules

      List of symbols. Each symbol names an optional module defined
      in the Kernel Report. The interpreter under test claims support
      of a module by listing it here.

  * test-options

      An environment with additional options influencing the run of the
      testsuite read from command line of the run script. The available
      options are:

        run-only (list of symbols, test group path)
        print-evaluations (boolean)
