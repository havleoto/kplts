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

($define! $quote
  ($vau (x) #ignore x))

($define! set!
  ($lambda (env lhs rhs)
    (eval (list $define! lhs (list $quote rhs)) env)))

($define! binds?
  (wrap $binds?))
