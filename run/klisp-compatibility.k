;;;
;;; klisp-compatibility.k
;;;
;;; Compatibility layer for klisp. See also klisp.sh.
;;;

($define! test-print
  ($lambda args
    (for-each
      ($lambda (x) (write-char #\space) (display x))
      args)
    (newline)))

($define! appropriate-number-of-calls 10000)

($define! supported-modules
  ((unwrap list) equivalence-under-mutation
                 pair-mutation
                 environment-mutation
                 inexact
                 ; narrow-inexact NOT SUPPORTED
                 rational
                 real
                 complex))

($define! test-options
  ($parse-options (cdr (get-script-arguments))
    (run-only ())
    (print-evaluations #f)))

