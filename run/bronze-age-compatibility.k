;;;
;;; bronze-age-compatibility.k
;;;
;;; Compatibility layer for Bronze Age Lisp. See also bronze-age.sh.
;;;

($unless ($binds? (get-current-environment) binds?)
  ($define! binds? (wrap $binds?)))

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
