;;;
;;; icbink-compatibility.k
;;;
;;; Compatibility layer for icbink. See also icbink.sh.
;;;

($define! error
  (wrap ($vau args denv
    (eval (cons + args) denv))))

($define! test-print println)

($define! appropriate-number-of-calls 1000)

($define! supported-modules
  ((unwrap list) environment-mutation))

($define! test-options
  ($bindings->environment
    (run-only ())
    (print-evaluations #f)))

(load "../support/utils.k")
(load "../support/checks.k")
(load "../support/fuzz.k")
(load "../support/hierarchy.k")
(load "../support/random.k")
(load "suite.k")
