;;;
;;; keyed-static-variables.k
;;;
;;; Test make-keyed-static-variable.
;;;

($test-group keyed-static-variables
    ((cite (kernel-report 11))
     (plan make-keyed-static-variable interaction))

  ($test-group make-keyed-static-variable
      ((cite (kernel-report 11 1 1))
       (plan return-list fresh-applicatives error-handling
             binder accessor))

    ($test-group return-list
        ((cite (kernel-report 11 1 1)
               "returns a list of the form (b a), where b and a are applicatives")
         (number 2))
      ($check equal? (length (make-keyed-static-variable)) 2)
      ($check (apply applicative? (make-keyed-static-variable))))

    ($test-group fresh-applicatives
        ((cite (kernel-report 11 1 1)
               "Each call to make-keyed-static-variable returns different b and a.")
         (number 3))
      ($check (not? (equal? (make-keyed-static-variable)
                            (make-keyed-static-variable))))
      ($let (((b1 a1) (make-keyed-static-variable))
             ((b2 a2) (make-keyed-static-variable)))
        ($check (not? (equal? a1 a2)))
        ($check (not? (equal? b1 b2)))))

    ($test-group error-handling
        ((number 10))
      ($fuzz-applicative 10 make-keyed-static-variable
        ($lambda (x) (null? x))
        (1) (1 2)))

    ($test-group binder
        ((cite (kernel-report 11 1 1)
               "/b/ takes two arguments, the second of which must be an
                environment. It constructs and returns a child-environment
                of its second argument, with initially no local bindings.")
         (plan fresh-environment child-environment no-local-bindings error-handling))

      ($test-group fresh-environment
          ((number 7))
        ($check (environment? ((car (make-keyed-static-variable))
                               42
                               (get-current-environment))))
        ($let* (((b a) (make-keyed-static-variable))
                (p     (get-current-environment))
                (e1    (b 0 p))
                (e2    (b 0 p))
                (e3    (b 1 p)))
          ($check (not? (equal? e1 e2)))
          ($check (not? (equal? e2 e3)))
          ($check (not? (equal? e3 e1)))
          ($set! e1 b 1)
          ($set! e2 b 2)
          ($set! e3 b 3)
          ($check equal? ($remote-eval b e1) 1)
          ($check equal? ($remote-eval b e2) 2)
          ($check equal? ($remote-eval b e3) 3)))

      ($test-group child-environment
          ((number 3))
        ($let* (((b a) (make-keyed-static-variable))
                (p     ($bindings->environment (a 42)))
                (e     (b () p)))
          ($check (not? (equal? e p)))
          ($set! p a 1)
          ($check equal? ($remote-eval a e) 1)
          ($set! p a 2)
          ($check equal? ($remote-eval a e) 2)))

      ($test-group no-local-bindings
          ((number 10))
        ($let* (((b a) (make-keyed-static-variable))
                (p (b 0 (make-environment)))
                (q (make-kernel-standard-environment))
                (r (b 0 q)))
          (for-each
            ($lambda (s)
              ($check (not? (binds? p s)))
              ($check equal? (eval s r) (eval s q)))
            ((unwrap list)
              list $if $sequence $define! cons))))

      ($test-group error-handling
          ((number 20))
        ($fuzz-applicative 20 (car (make-keyed-static-variable))
          ($lambda (x)
            ($and? (finite-list? x)
                   (equal? (length x) 2)
                   (environment? (cadr x))))
          (list (make-environment)))))

      ($test-group accessor
          ((plan zero-arguments depth-first-traversal signal-error))

        ($test-group zero-arguments
          ((cite (kernel-report 11 1 1)
                "applicative that takes zero arguments")
           (number 3))
        ($let (((b a) (make-keyed-static-variable)))
          ($remote-eval
            ($sequence ($check-error (a 1))
                       ($check-error (a 1 2))
                       ($check-error (a b)))
            (b 42 (get-current-environment)))))

        ($test-group depth-first-traversal
            ((cite (kernel-report 11 1 1)
                   "/a/ returns the value of the first argument passed to /b/ in the
                    [...] environment encountered by a depth-first traversal of the
                    improper ancestors")
             (number 9))
          ($let* (((b a) (make-keyed-static-variable))
                  ;;
                  ;;    e1     e2
                  ;;   |  |   |  |
                  ;;   |  +-+-+  |
                  ;;   |    |    |
                  ;;  e3    e4   e5
                  ;;   |    |    |
                  ;;   +----+----+
                  ;;        |
                  ;;        e6
                  ;;
                  (e1      (make-environment))
                  (e2      (make-environment))
                  (e3      (b 1 e1))
                  (e4      (make-environment (b 2 e1) (b 3 e2)))
                  (e5      (b 4 e2))
                  (e6      (make-environment e3 e4 e5)))
            ($check equal? (eval (list a) e3) 1)
            ($check equal? (eval (list a) e4) 2)
            ($check equal? (eval (list a) e5) 4)
            ($check equal? (eval (list a) e6) 1))
          ($let* (((b a) (make-keyed-static-variable))
                  (e0    (make-environment))
                  (e1    (b 1 e0))
                  (e2    (b 2 e0))
                  (e3    (b 3 e0))
                  (e123  (make-environment e1 e2 e3))
                  (e231  (make-environment e2 e3 e1))
                  (e312  (make-environment e3 e1 e2))
                  (eaux  (make-environment e231 e123 e312)))
            ($check equal? (eval (list a) e123) 1)
            ($check equal? (eval (list a) e231) 2)
            ($check equal? (eval (list a) e312) 3)
            ($check equal? (eval (list a) eaux) 2))
          ($let* (((b a)    (make-keyed-static-variable))
                  ;;
                  ;;     e0
                  ;;     |
                  ;;   +-+-+
                  ;;   |   |
                  ;;  e1   e3
                  ;;   |   |
                  ;;  e2   e4
                  ;;   |   |
                  ;;   +-+-+
                  ;;     |
                  ;;     e5
                  ;;
                  (e0       (make-environment))
                  (e1       (b 1 e0))
                  (e2       (b 2 e1))
                  (e3       (b 3 e0))
                  (e4       (b 4 e1))
                  (e5       (make-environment e2 e4)))
            ($check equal? (eval (list a) e5) 2)))

        ($test-group signal-error
            ((cite (kernel-report 11 1 1)
                   "If /e/ has no improper ancestors constructed via /b/,
                    an error is signaled.")
             (number 3))
          ($check-error ((cadr (make-keyed-static-variable))))
          ($let (((b1 a1) (make-keyed-static-variable))
                 ((b2 a2) (make-keyed-static-variable))
                 (parent  (make-environment)))
            ($check-error (eval (list a1) (b2 0 parent)))
            ($check-error (eval (list a2) (b1 1 parent)))))))

  ($test-group interaction
      ((plan $let $letrec $let-redirect
             $vau $lambda $bindings->environment
             $provide! get-module))

    "TODO"))
