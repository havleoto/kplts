Tests
=====

  The tests are organized in a hierarchy of *test groups*. The top
  levels of the hierarchy follow the structure of chapters in
  the Kernel Report. The root group of the hierarchy is called *kplts*
  and it is defined in [suite.k](suite.k).

  The test groups are defined by the operative $test-group. The
  syntax is described in [hierarchy.k](../support/hierarchy.k).
  Here, we show a commented example of the [length](pairs-and-lists.k#L319))
  test group. The group is placed in the hierarchy:

  - kplts
    - kernel-core
      - pairs-and-list
        - length

  The test group is defined by

```
1  ($test-group length
2      ((cite (kernel-report 6 3 1)
3             "returns the number of consecutive cdr references
4              that can be followed starting from /object/")
5       (plan finite-list improper-list non-list cyclic-list))
```

  The second argument of *$test-group* contains some meta data.
  The form `(cite ...)` (lines 2-4) refers to the specification of
  the functionality covered by this test group. The *cite* form is
  purely informational; it gives a section number (6.3.1.) and a
  verbatim quotation so everybody can quickly look up the specification.

  The form `(plan ...)` declares the subgroups in advance. The
  purpose of the *plan* form is catching bugs in the testsuite.
  The support code prints a warning if any of the declared subgroups
  is not actually defined in the body of the *$test-group*.

```
6    ($test-group finite-list
7         ((number 2))
8       ($check equal? (length (cons () ())) 1)
9       ($check equal? (length (list #t #t #f #f #t #t #f #f)) 8))
```
  The subgroup finite-list is defined similarly. In this case, the
  metadata give the number of checks to be executed. The purpose is,
  again, cross-checking that all tests are implemented.

  The forms in the body of the $test-group are executed in sequence.
  The support code defines several forms for checking test conditions.
  On line 8, we test the condition that the length of the single-element
  list `(())` created by `(cons () ())` is equal to the expected value 1.
  The `($check ...)` form takes care of accumulating the test pass/fail
  result and guarding against errors (and other abnormal continuation
  passes) that may arise during evaluation. More helper combiners are
  defined in [checks.k](../support/checks.k).
