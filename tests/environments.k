($test-group environments
    ((cite (kernel-report 4 8))
     (plan equality
           eval
           make-environment))

  ($test-group equality
      ((cite (kernel-report 4 8)
             "Two environments are equal? iff they are eq?")
       (number 2))
    ($let ((e1 (make-environment))
           (e2 (make-environment)))
      ($check equal? e1 e1)
      ($check (not? (equal? e1 e2)))))

  ($test-group eval
      ((cite (kernel-report 4 8 3))
       (plan normal-operation
             error-handling))

    ($test-group normal-operation
        ((number 5))
      ($check (applicative? eval))
      ($check equal?
              (eval (list + ($quote a) ($quote b))
                    ($bindings->environment (a 1) (b 2)))
              3)
      ; Check that the expression can't access bindings from the static
      ; environment of definition of eval.
      ($check-error (eval (list ($quote cons) "a" "b") (make-environment)))
      ; Check that the expression can't access bindings from the dynamic
      ; environment of the call to eval.
      ($let ((a 1)
             (b 2))
        ($check-error (eval (list + ($quote a) ($quote b)) (make-environment))))
      ; For contrast, check that we can evaluate in an empty environment when
      ; all atoms in the expression evaluate to themselves.
      ($let ((a 1)
             (b 2))
        ; The body of eval never sees the symbols '+', 'a', or 'b', because
        ; eval is an applicative.
        ($check equal?
                (eval (list + a b) (make-environment))
                3)))

    ($test-group error-handling
        ((number 4))
      ; arity
      ($check-error (eval))
      ($check-error (eval 1))
      ($check-error (eval 1 (make-environment) (make-environment)))
      ; type: second argument must be an environment.
      ($check-error (eval #t "not an environment"))))

  ($test-group make-environment
      ((cite (kernel-report 4 8 4))
       (plan normal-operation
             parent-list-mutation
             cyclic-parent-list
             error-handling))
    ($test-group normal-operation
        ((number 5))
      ; ground environment doesn't leak into the returned environment.
      ($check (not? ($binds? (make-environment) car)))
      ; dynamic environment doesn't leak into the returned environment.
      ($let ((x 1))
        ($check (not? ($binds? (make-environment) x))))
      ; a binding from a parent environment is exposed.
      ($check equal?
        (eval ($quote x) (make-environment ($bindings->environment (x "x's value"))))
        "x's value")
      ; a binding from a parent environment in position >1
      ($check equal?
        (eval ($quote x) (make-environment
                           (make-environment)
                           ($bindings->environment (x "x's value"))))
        "x's value")
      ; parent environments get built in the right order
      ; (note it's only the order of the environments as constructed by
      ; make-environment that we're testing here.  environment-concepts.k tests
      ; depth-first search semantics in general)
      ($check equal?
        (eval ($quote x) (make-environment
                           ($bindings->environment (x "shadowing x"))
                           ($bindings->environment (x "shadowed x"))))
        "shadowing x"))

    ; XXX: I haven't tested this because icbink doesn't implement the pair
    ; mutation module.  - euccastro@gmail.com
    ($when ($binds? (get-current-environment) set-car!)
      ($test-group parent-list-mutation
          ((cite (kernel-report 4 8 4)
                 "The constructed environment internally stores its list of
                 parents independent of the first- class list environments, so
                 that subsequent mutation of environments will not change the
                 parentage of the constructed environment.")
           (number 1))
        ($let* ((parent-envs (list ($bindings->environment (a 1))))
                (env (apply make-environment parent-envs)))
          (set-car! parent-envs ($bindings->environment (a 2)))
          ($check equal? (eval ($quote a) env) 1))))

    ; XXX: I haven't tested this because icbink doesn't implement the pair
    ; mutation module.  - euccastro@gmail.com
    ($when ($binds? (get-current-environment) set-cdr!)
      ($test-group cyclic-parent-list
          ((cite (kernel-report 4 8 4)
                 "If the provided list environments is cyclic, the constructed
                 environment will still check each of its parents at most once,
                 and signal an error if no binding is found locally or in any of
                 the parents.")
           (number 1))
        ($let ((parent-envs (list ($bindings->environment (a 1)))))
          (set-cdr! parent-envs parent-envs)
          ($let ((env (apply make-environment parent-envs)))
            ($check ($binds? env a))
            ($check (not? ($binds? env b)))
            ($check-error (eval ($quote b) env))))))

    ($test-group error-handling
        ((number 5))
      ; type error: non-environment at various positions.
      ($let ((env (make-environment))
             (non-env "not an environment"))
          ($check-error (make-environment non-env))
          ($check-error (make-environment env non-env))
          ($check-error (make-environment non-env env))
          ($check-error (make-environment env non-env env))
          ($check-error (make-environment env env non-env))))))

