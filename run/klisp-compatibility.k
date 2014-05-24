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
