;;;
;;; bronze-age-compatibility.k
;;;
;;; Compatibility layer for Bronze Age Lisp. See also bronze-age.sh.
;;;

($define! test-print
  ($lambda args
    (for-each
      ($lambda (x)
        (write-char #\space)
        ($cond
          ((error-object? x)
            (format #t "#[error ~w ~w ~w]"
              (error-object-message x)
              (error-object-irritants x)
              (error-object-source x)))
          (#t
            (display x))))
      args)
    (newline)))

($define! appropriate-number-of-calls 10000)

($define! supported-modules
  ($quote* equivalence-under-mutation
           pair-mutation
           environment-mutation))

($define! test-options
  ($parse-options
      ;; (get-interpreter-arguments) returns () in scripts loaded using
      ;; -l option, because command line parsing is not yet finished.
      ;; TODO: Fix that in Bronze Age Lisp.
      (list-tail (get-interpreter-arguments)
                 16)
    (run-only ())
    (print-evaluations #f)))
