;;;
;;; utils.k
;;;
;;; Various utility combiners.
;;;

;;
;; ($define-nonstandard! NAME VALUE)
;;
;;   Perform ($define! NAME VALUE), unless NAME is already bound.
;;
($define! $define-nonstandard!
  ($vau (symbol value) denv
    ($if ((wrap $binds?) denv symbol)
      (test-print "; non-standard binding" symbol "already defined")
      (eval (list $define! symbol value) denv))))

;;
;; Define $when, $unless, $quote, ... using standard combiners, unless
;; the implementation provides the bindings as built-ins.
;;

($define-nonstandard! $when
  ($vau test-body denv
    (eval (list $cond test-body) denv)))

($define-nonstandard! $unless
  ($vau (test . body) denv
    (eval (list $cond (list test #inert) (list* #t body)) denv)))

($define-nonstandard! $quote
  ($vau (x) #ignore x))

($define-nonstandard! set!
  ($lambda (env lhs rhs)
    (eval (list $define! lhs (list $quote rhs)) env)))

($define-nonstandard! binds?
  (wrap $binds?))

;;
;; More utilities.
;;

($define! $increment!
  ($vau (e s) denv
    ($let ((e (eval e denv)))
      (set! e s (+ (eval s e) 1)))))

($define! list-product
  ($lambda (xs ys)
    (apply append
           (map ($lambda (y) (map ($lambda (x) (list x y)) xs)) ys))))
