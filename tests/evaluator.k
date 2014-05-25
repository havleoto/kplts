;;;
;;; evaluator.k
;;;
;;; Test Kernel evaluator algorithm.
;;;

($test-group evaluator
    ((cite (kernel-report 3 3))
     (plan dynamic-environment
           self-evaluating-objects
           operative-combinations
           applicative-combinations
           evaluation-order))

  ($test-group dynamic-environment
      ((cite (kernel-report 3 3)
             "The environment passed to an operative is the dynamic environment
              in which the combiner was invoked (as opposed to the static
              environment in which, if compound, it was constructed).")
       (number 14))
    ($define! e1 (make-environment))
    ($define! e2 (make-environment))
    ($define! f ($vau #ignore denv ($check equal? denv e1) f))
    ($define! g ($vau #ignore denv ($check equal? denv e2) g))
    ($define! h ($vau x #ignore (eval x e2) #t))
    ;; 1 check
    (eval-protect (list f) e1)
    ;; 2 checks
    (eval-protect (list (list f)) e1)
    ;; 3 checks
    (eval-protect (list (list (list f))) e1)
    ;; 6 checks
    (eval-protect (list $sequence (list f)
                                  (list h g)
                                  (list f)
                                  (list h (list g))
                                  (list f))
                  e1)
    ;; 2 checks
    (eval-protect (list $if (list h g)
                            (list f)
                            (list f))
                  e1))

  ($test-group self-evaluating-objects
      ((cite (kernel-report 3 3)
             "to evaluate an object o in an environment e [...]
              If o isn't a symbol and isn't a pair, the evaluator returns o.")
       (number 30))
    (for-each
      ($lambda (o)
        ($check equal? (eval o (make-environment)) o)
        ($check equal? (eval o (make-kernel-standard-environment)) o))
      (list #t #f #inert #ignore
            0 1 -1
            $if list
            ($vau #ignore #ignore #inert) ($lambda #ignore #ignore #inert)
            (make-environment) (get-current-environment)
            root-continuation ($let/cc k k))))

  ($test-group operative-combinations
      ((cite (kernel-report 3 3)
             "Let a and d be the car and cdr of o. a is evaluated in e; call
              its result f. (a) If f is an operative, then f is called with
              input object d and input environment e, and the result is the
              result of the combination.")
       (number 2))
    ($define! f ($vau #ignore #ignore 1))
    ($define! g ($vau #ignore #ignore 2))
    ($check equal? (f x) 1)
    ($check equal? (g x y z) 2))

  ($test-group applicative-combinations
      ((cite (kernel-report 3 3)
             "Let f' be the underlying combiner of f. The elements of list d are
              evaluated in e; let d' be a list of their values. The cons of f'
              with d' is evaluated in e, and the result is the result of the
              combination.")
       (plan normal-operation head-not-combiner ptree-not-list))

    ($test-group normal-operation
        ((number 6))
      ($define! f
        ($vau x e 1))
      ($define! g
        ($vau x e
          ($check equal? x (list (wrap f))) 2))
      ($define! h
        ($vau (x y) e
          ($check equal? x (wrap f))
          ($check equal? y (wrap g))
          3))
      ($check equal? ((wrap f)) 1)
      ($check equal? ((wrap g) (wrap f)) 2)
      ($check equal? ((wrap h) (wrap f) (wrap g)) 3))

    ($test-group head-not-combiner
       ((cite (kernel-report 3 3)
             "Otherwise, f must be an applicative [...]")
        (number 39))
      (for-each
        ($lambda (f)
          ($check-error (eval ($quote (f #t #t #t))
                              ($bindings->environment (f f))))
          ($check-error (eval (list (list ($vau #ignore #ignore f)) #t #t #f)
                              (make-environment)))
          ($unless (symbol? f)
            ($check-error (eval (list f #f #f #t)
                                (make-environment)))))
        (list ($quote a) ($quote list) ($quote $if)
              #t #f #inert #ignore
              0 1 -1
              (make-environment) (get-current-environment)
              root-continuation ($let/cc k k))))

    ($test-group ptree-not-list
        ((cite (kernel-report 3 3)
               "[...] and d must be a list [...]")
         (number 36))
      (for-each
        ($lambda ((f x))
          ($check-error (eval (cons f x) (make-kernel-standard-environment))))
        (list-product (list + ($quote +) (wrap $sequence) (wrap (unwrap or?)))
                      (list 1 ($quote a) #t #ignore #inert
                            $vau list (make-environment) root-continuation)))))

  ($test-group evaluation-order
      ((number 4))
    ($check-effects
      (((eff 1 $if) (eff 2 #t) (eff 3 list) (eff 4 list))
       (eff 5 1))
      (1 2 3 5))
    ($check-effects
      ($letrec ((f ($vau #ignore #ignore (eff 1 g)))
                (g ($vau #ignore #ignore (eff 2 h)))
                (h ($vau #ignore #ignore (eff 3 #t))))
        (((f))))
      (1 2 3))
    ($check-effects
      ($letrec ((f ($lambda (x) (eff 1 #inert)))
                (g ($lambda (x) (eff x x))))
        (f (g (g 2))))
      (2 2 1))
    ($check-effects
      ($letrec ((f ($lambda (x) (eff 1 #inert)))
                (g ($lambda (x) (eff x x))))
        (f 0 (g (g 3)) 0))
      (3 3))))
