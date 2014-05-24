;;;
;;; fuzz.k
;;;
;;; Testing based on random mutations.
;;;
;;; ($fuzz-applicative N F P? INPUT-SAMPLE-1 INPUT-SAMPLE-2 ...)
;;;
;;;  Apply F on random parameter trees which do NOT satisfy the
;;;  unary predicate P?. The applicative F is expected to raise
;;;  an error. The parameter trees are produced by mutating
;;;  INPUT-SAMPLEs. In total, N trees are tested.
;;;

($provide! (repeat-change-es random-mutations)

  ($define! pool
    (list () (cons list list) (list 1 2 3)
          #t #f
          #inert #ignore
          0 1 -1
          ($quote a) ($quote b)
          $sequence cons
          (make-environment)))

  ($define! change-es
    ($lambda (n x)
      ($cond
        (($or? (<=? n (random-integer 5)))
          (random-list-element pool))
        ((boolean? x)
          (not? x))
        ((operative? x)
          (wrap x))
        ((applicative? x)
          (unwrap x))
        ((pair? x)
          ($random-choice
            (cons (random-list-element pool) x)
            (cons (change-es (- n 1) (car x)) (cdr x))
            (cons (car x) (change-es (- n 1) (cdr x)))))
        (#t
          (random-list-element pool)))))

  ($define! repeat-change-es
    ($lambda (m n x)
      ($if (<=? m 0)
        x
        (repeat-change-es (- m 1) n (change-es n x)))))

  ($define! random-mutations
    ($lambda (count pred? inputs)
      ($letrec ((gen
        ($lambda (n m a)
          ($cond
            ((<=? n 0)
              a)
            ((<=? m 0)
              (error "random-mutations: too many rejected samples"))
            (#t
              ($let ((x (repeat-change-es (+ 1 (random-integer 3))
                                          10
                                          (random-list-element inputs))))
                ($if (pred? x)
                  (gen (- n 1) m (cons x a))
                  (gen n (- m 1) a))))))))
        (gen count (* 20 count) ())))))

($provide! ($fuzz-applicative)

  ($define! fuzz-applicative
    ($lambda (count f valid-ptree? input-samples)
      (for-each
        ($lambda (ptree)
          ($define! form
            ($if (finite-list? ptree)
              ($random-choice
                (cons (unwrap f) ptree)
                (list apply f (list $quote ptree))
                (cons f (map ($lambda (x) (list $quote x)) ptree)))
              ($random-choice
                (cons (unwrap f) ptree)
                (list apply f (list $quote ptree)))))
          ;(test-print "fuzz: " form)
          ($define! (xe xr)
            (eval-protect form (make-kernel-standard-environment)))
          (test-result! #ignore (equal? xe event-error) form xr))
        (random-mutations count
                          ($lambda (x) (not? (valid-ptree? x)))
                          input-samples))))

  ($define! $fuzz-applicative
    ($vau (count f valid-ptree? . ptree-samples) denv
      ($with-random
        (fuzz-applicative
          (eval count denv)
          (eval f (make-kernel-standard-environment))
          (eval valid-ptree? denv)
          (map
            ($lambda (ptree) (eval (cons list ptree) denv))
            ptree-samples))))))
