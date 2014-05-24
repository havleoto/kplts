;;;
;;; environment-concepts.k
;;;

($test-group environment-concepts
    ((cite (kernel-report 3 2))
     (plan depth-first-search error-handling))

  ($define! extend-environment
    ($vau (bindings parents) denv
      ($define! env (apply make-environment (eval (cons list parents) denv)))
      (for-each
        ($lambda (lhs rhs) (set! env lhs (eval rhs denv)))
        bindings)
      env))

  ($test-group depth-first-search
      ((cite (kernel-report 3 2)
             "When a symbol s is looked up in an environment e, a depth-first
              search is conducted on the improper ancestors of e, taking the
              parents in listed order, to find a binding of s to some value.")
       (number 12))

      ($define! a ($bindings->environment (x 1) (y 2)))
      ($define! b ($bindings->environment (x 3) (z 4)))

      ($define! c (make-environment a b))
      ($check equal? ($remote-eval x c) 1)
      ($check equal? ($remote-eval y c) 2)
      ($check equal? ($remote-eval z c) 4)

      ($define! d (make-environment b a))
      ($check equal? ($remote-eval x d) 3)
      ($check equal? ($remote-eval y d) 2)
      ($check equal? ($remote-eval z d) 4)

      ($define! e (make-environment c d))
      ($check equal? ($remote-eval x e) 1)
      ($check equal? ($remote-eval y e) 2)
      ($check equal? ($remote-eval z e) 4)

      ($define! f (make-environment d c))
      ($check equal? ($remote-eval x f) 3)
      ($check equal? ($remote-eval y f) 2)
      ($check equal? ($remote-eval z f) 4)))
