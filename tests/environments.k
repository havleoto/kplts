($test-group environments
    ((cite (kernel-report 4 8)
           (kernel-report 5 10)
           (kernel-report 6 7))
     (plan equality
           eval
           make-environment
           $let
           $binds?
           get-current-environment
           make-kernel-standard-environment
           $let*
           $letrec
           $letrec*
           $let-redirect
           $let-safe
           $remote-eval
           $bindings->environment))

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

      ($test-group parent-list-mutation
          ((cite (kernel-report 4 8 4)
                 "The constructed environment internally stores its list of
                 parents independent of the first-class list environments, so
                 that subsequent mutation of environments will not change the
                 parentage of the constructed environment.")
            (require-modules pair-mutation)
            (number 1))
        ($let* ((parent-envs (list ($bindings->environment (a 1))))
                (env (apply make-environment parent-envs)))
          (set-car! parent-envs ($bindings->environment (a 2)))
          ($check equal? (eval ($quote a) env) 1)))

      ($test-group cyclic-parent-list
          ((cite (kernel-report 4 8 4)
                 "If the provided list environments is cyclic, the constructed
                 environment will still check each of its parents at most once,
                 and signal an error if no binding is found locally or in any of
                 the parents.")
           (require-modules pair-mutation)
           (number 3))
        ($let ((parent-envs (list ($bindings->environment (a 1)))))
          (set-cdr! parent-envs parent-envs)
          ($let ((env (apply make-environment parent-envs)))
            ($check ($binds? env a))
            ($check (not? ($binds? env b)))
            ($check-error (eval ($quote b) env)))))

    ($test-group error-handling
        ((number 5))
      ; type error: non-environment at various positions.
      ($let ((env (make-environment))
             (non-env "not an environment"))
          ($check-error (make-environment non-env))
          ($check-error (make-environment env non-env))
          ($check-error (make-environment non-env env))
          ($check-error (make-environment env non-env env))
          ($check-error (make-environment env env non-env)))))

;;
;; $let
;;

  ($test-group $let
      ((cite (kernel-report 5 10))
       (plan lambda-equivalence environments
             body-left-to-right empty-body tail-context
             finite-bindings binding-forms symbol-occurence))

    ($test-group lambda-equivalence
        ((cite (kernel-report 5 10)
               "The expression
                  ($let ((form1 exp1) ... (formN expN)) . objects)
                is equivalent to
                  (($lambda (form1 ... formN) . objects) exp1 ... expN)")
         (number 6))
      ($eval-table
        (($let () #t)                        (($lambda () #t)))
        (($let ((a 1)) 2 a)                  (($lambda (a) 2 a) 1))
        (($let ((#ignore #ignore)) #inert)   (($lambda (#ignore) #inert) #ignore))
        (($let ((() ())) 3)                  (($lambda (()) 3) ()))
        (($let ((a 1) (b 2)) (+ a b))        (($lambda (a b) (+ a b)) 1 2))
        (($let (((a b) (list 1 2)) (c 3)) b) (($lambda ((a b) c) b) (list 1 2) 3))))

    ($test-group environments
        ((cite (kernel-report 5 10)
               "/expK/ are first evaluated in the dynamic environment [...]
                then a child environment /e/ of the dynamic environment is
                created [...] the subexpressions of objects are evaluated
                in /e/")
          (number 13))
      ($define! parent-env (make-kernel-standard-environment))
      ($set! parent-env outside #t)
      ($set! parent-env $check-outside
        ($vau x e
          ($check (equal? e parent-env))
          ($check (not? ($binds? e a)))
          ($check (not? ($binds? e b)))
          ($check ($remote-eval outside parent-env))
          x))
      ($set! parent-env $check-inside
        ($vau x e
          ($set! parent-env inside #f)
          ($check (not? (equal? e parent-env)))
          ($check ($binds? e a))
          ($check ($binds? e b))
          ($set! parent-env z 1)
          ($check equal? ($remote-eval z e) 1)
          ($set! parent-env z 2)
          ($check equal? ($remote-eval z e) 2)
          x))
      ($remote-eval
         ($let ((a ($check-outside 1))
                (b ($check-outside 2)))
           ($check-inside #inert)
           (list a b))
         parent-env))

    ($test-group body-left-to-right
        ((cite (kernel-report 5 10)
               "subexpressions of /objects/ are evaluated [...] from left to right")
         (number 3))
      ($define! state
        (make-environment))
      ($define! note
        ($lambda (k)
          ($set! state x (+ k (* 10 ($remote-eval x state))))
          ($remote-eval x state)))
      ($set! state x 0)
      ($check equal?
        ($let () (note 4) (note 2) (note 7))
        427)
      ($set! state x 0)
      ($check equal?
        ($let (($if 9) ($let 8)) (note $if) (note $let))
        98)
      ($set! state x 0)
      ($check equal?
        ($let ((a 1)) (note a) (note 2) (note 3) (note a) (note 4) (note 5))
        123145))

    ($test-group empty-body
        ((cite (kernel-report 5 10)
               "if /objects/ is empty the result is inert")
         (number 3))
      ($eval-table
        (($let ())            #inert)
        (($let ((x 1)))       #inert)
        (($let ((x 1) (y 2))) #inert)))

    ($test-group tail-context
        ((cite (kernel-report 5 10)
               "the last [of objects] evaluated as a tail context")
         (number 1))
      ($define! f
        ($lambda (x n)
          ($if (positive? n)
            ($let ((y (+ x 1))) (f y (- n 1)))
            x)))
      ($check equal? (f 0 appropriate-number-of-calls) appropriate-number-of-calls))

    ($test-group finite-bindings
        ((cite (kernel-report 5 10)
               "/bindings/ should be a finite list")
         (require-modules pair-mutation)
         (number 2))
      ($check-error ((wrap $let) (cyclic-list (list #ignore #ignore)) 0))
      ($check-error ((wrap $let) (cons (list () ()) (cyclic-list (list () ()))) 0)))

    ($test-group binding-forms
        ((cite (kernel-report 5 10)
               "list of formal-parameter-tree/expression pairings, each of the
                form (/formals/ /expression/), where each /formals/ is a formal
                parameter tree")
         (number 5))
      ($check-error ($let #f 1))
      ($check-error ($let (a) 2))
      ($check-error ($let (a 0) #inert))
      ($check-error ($let loop ((x 0)) #inert))
      ($check-error ($let ((a 1 2)) 3)))

    ($test-group symbol-occurence
        ((cite (kernel-report 5 10)
               "no symbol occurs in more than one of the /formals/")
         (number 3))
      ($check-error ($let ((a 1) (a 2)) a))
      ($check-error ($let ((a 1) (a 2) (a 3)) a))
      ($check-error ($let (((x y) (list 1 2)) (y 2)) x)))))
