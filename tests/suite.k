;;;
;;; suite.k
;;;
;;; Root of the test suite.
;;;
($test-suite KPLTS
    ((plan kernel-syntax
           kernel-concepts
           kernel-core
           kernel-standard
           kernel-extensions))
  ;;
  ;; Syntax of Kernel Language as described in [KR, section 2].
  ;;
  ($test-group kernel-syntax
      ((cite (kernel-report 2))
       (plan lexemes
             ;... is there anything else to Kernel syntax than lexemes?
             ))
    (load "lexemes.k"))
  ;;
  ;; Semantics of Kernel Language as described in [KR, section 3].
  ;;
  ($test-group kernel-concepts
      ((plan references
             environment-concepts
             evaluator
             types
             cyclic-references
             tail-recursion)
       (cite (kernel-report 3)))
    (load "types.k")
    (load "environment-concepts.k")
    (load "evaluator.k")
    (load "tail-recursion.k"))
  ;;
  ;; Ten core modules [KR, sections 4-6].
  ;;
  ($test-group kernel-core
      ((plan booleans
             equivalence-under-mutation
             equivalence-up-to-mutation
             symbols
             control
             pairs-and-lists
             pair-mutation
             environments
             environment-mutation
             combiners)
       (cite (kernel-report "4-6")))
    (load "booleans.k")
    (load "pairs-and-lists.k")
    (load "environments.k")
    (load "combiners.k"))

  ;;
  ;; The non-core modules from [KR, sections 7-15].
  ;;
  ($test-group kernel-standard
      ((plan continuations
             encapsulations
             promises
             keyed-dynamic-variables
             keyed-static-variables
             numbers
             strings
             characters
             ports))
    (load "continuations.k")
    (load "encapsulations.k")
    (load "numbers.k")
    (load "keyed-dynamic-variables.k")
    (load "keyed-static-variables.k"))
  ;;
  ;; Extensions [R7RS, klisp].
  ;;
  ($test-group kernel-extensions
      ((plan vectors
            bytevectors
            error-objects))))

