;;;
;;; klink-compatibility.k
;;;
;;; Compatibility layer for Klink. See also klink.sh.
;;;

;;
;; Klink's map and for-each does not evaluate in the dynamic
;; environment. Fix it here.
;;

($define! (map for-each)
  ($let ((klink:for-each for-each)
         (klink:map map))
    (list
      (wrap ($vau (f . xs) denv
        (apply klink:map
              (cons ($lambda args (apply f args denv)) xs))))
      (wrap ($vau (f . xs) denv
        (apply klink:for-each
              (cons ($lambda args (apply f args denv)) xs)))))))

;;
;; Klink does not define (filter ...). We cannot use the (filter ...)
;; from the Kernel Report, because Klink (append ...) does not support
;; more than two arguments. We go with a non-compliant definition.
;;

($define! filter
  ($lambda (accept? xs)
    ($cond
      ((null? xs)
        ())
      ((apply accept? (list (car xs)))
        (cons (car xs) (filter accept? (cdr xs))))
      (#t
        (filter accept? (cdr xs))))))

($define! positive?
  ($lambda xs
    (apply <=? (cons 0 xs))))

;;
;;
;;

($define! test-print
  ($lambda args
    (for-each
      ($lambda (x) (display " ") (display x))
      args)
    (newline)))

($define! appropriate-number-of-calls 200)

(load "../support/utils.k")
(load "../support/checks.k")
(load "../support/hierarchy.k")
(load "../support/random.k")

;;
;;
;;

(load "suite.k")
