Run scripts
===========

  A run script is responsible for loading the test suite in its respective
  interpreter. The interpreter should load all *.k files in the "support"
  directory and then load suite.k in "tests." The directory "tests" is
  also the working directory of the run script.
