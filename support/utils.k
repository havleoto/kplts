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
;;   ($increment! ENVIRONMENT SYMBOL)
;;
;;     Increment the value bound to SYMBOL in ENVIRONMENT.
;;
;;   (list-product XS YS)
;;
;;     Compute cartesian product of lists. Return a list of lists (X Y),
;;     where X is an element of XS and Y is an element of YS.
;;
;;   (cyclic-list X1 ... Xn)
;;
;;     Build cyclic list (X1 ... Xn X1 ... Xn X1 ...)
;;

($define! $increment!
  ($vau (e s) denv
    ($let ((e (eval e denv)))
      (set! e s (+ (eval s e) 1)))))

($define! list-product
  ($lambda (xs ys)
    (apply append
           (map ($lambda (y) (map ($lambda (x) (list x y)) xs)) ys))))

($define! cyclic-list
  ($if ($binds? (get-current-environment) encycle!)
    ($lambda input
      ($let ((copy (map list* input)))
        (encycle! copy 0 (length copy))
        copy))
    ($lambda #ignore
      (error "cycle: The implementation does not support cyclic lists."))))
