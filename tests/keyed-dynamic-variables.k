;;;
;;; keyed-dynamic-variables.k
;;;
;;; Test make-keyed-dynamic-variable.
;;;

($test-group keyed-dynamic-variables
    ((cite (kernel-report 10))
     (plan make-keyed-dynamic-variable interaction))

  ($test-group make-keyed-dynamic-variable
      ((cite (kernel-report 10 1 1))
       (plan return-list fresh-applicatives error-handling
             binder accessor))

    ($test-group return-list
        ((cite (kernel-report 10 1 1)
               "returns a list of the form (b a), where b and a are applicatives")
         (number 2))
      ($check equal? (length (make-keyed-dynamic-variable)) 2)
      ($check (apply applicative? (make-keyed-dynamic-variable))))

    ($test-group fresh-applicatives
        ((cite (kernel-report 10 1 1)
               "Each call to make-keyed-dynamic-variable returns different b and a.")
         (number 3))
      ($check (not? (equal? (make-keyed-dynamic-variable)
                            (make-keyed-dynamic-variable))))
      ($let (((b1 a1) (make-keyed-dynamic-variable))
             ((b2 a2) (make-keyed-dynamic-variable)))
        ($check (not? (equal? a1 a2)))
        ($check (not? (equal? b1 b2)))))

    ($test-group error-handling
        ((number 10))
      ($fuzz-applicative 10 make-keyed-dynamic-variable
        ($lambda (x) (null? x))
        (1) (1 2)))

    ($test-group binder
        ((cite (kernel-report 10 1 1)
               "calls its second argument with no operands (nil operand tree) in
                a fresh empty environment, and returns the result")
         (plan nil-operand-tree empty-environment fresh-environment
               return-result error-handling))

      ($test-group nil-operand-tree
         ((number 2))
        ($let (((b . #ignore) (make-keyed-dynamic-variable)))
          (b 0 ($lambda operand ($check (null? operand))))
          (b 0 ($vau operand #ignore ($check (null? operand))))))

      ($test-group empty-environment
          ((number 2))
        ($let (((b . #ignore) (make-keyed-dynamic-variable)))
          (b 0 (wrap ($vau #ignore e ($check (not? ($binds? e b))))))
          (b 0 ($vau #ignore e ($check (not? ($binds? e b)))))))

      ($test-group fresh-environment
          ((number 6))
        ($define! check-different-environments
          ($lambda (e1 e2)
            ($check (not? (equal? e1 e2)))
            ($set! e1 x 1)
            ($set! e2 x 2)
            ($check equal? ($remote-eval x e1) 1)
            ($check equal? ($remote-eval x e2) 2)))
        ($define! (b . #ignore) (make-keyed-dynamic-variable))
        (check-different-environments
          (b 0 get-current-environment)
          (b 0 get-current-environment))
        (b #t ($vau #ignore e
               (b #t ($vau #ignore f
                      (check-different-environments e f))))))

      ($test-group return-result
          ((number 5))
        ($check (null? ((car (make-keyed-dynamic-variable)) 1 list)))
        ($check (inert? ((car (make-keyed-dynamic-variable)) 2 $sequence)))
        ($check equal? ((car (make-keyed-dynamic-variable)) 3 +) 0)
        ($check equal? ((car (make-keyed-dynamic-variable)) 4 inert?) #t)
        ($check equal?
          ($let (((b #ignore) (make-keyed-dynamic-variable)))
            (b b ($lambda () 42)))
          42))

      ($test-group error-handling
          ((number 10))
        ($fuzz-applicative 10 (car (make-keyed-dynamic-variable))
          ($lambda (x)
            ($and? (finite-list? x)
                   (equal? (length x) 2)
                   (combiner? (cadr x))))
          (list list))))


    ($test-group accessor
        ((plan zero-arguments return-value signal-error))

      ($test-group zero-arguments
          ((cite (kernel-report 10 1 1)
                "applicative that takes zero arguments")
           (number 3))
        ($let (((b a) (make-keyed-dynamic-variable)))
          (b 0 ($lambda ()
                 ($check-error (a 1))
                 ($check-error (a 1 2))
                 ($check-error (a b))))))

      ($test-group return-value
          ((cite (kernel-report 10 1 1)
                 "If the call to /a/ occurs within the dynamic extent of a call
                  to /b/, then /a/ returns the value of the first argument passed
                  to /b/ in the smallest enclosing dynamic extent of a call to /b/.")
           (number 7))
        ($check equal?
                ($let (((b a) (make-keyed-dynamic-variable))) (b 42 a))
                42)
        ($let (((b a) (make-keyed-dynamic-variable)))
          (b (list 1 2) ($vau #ignore #ignore
            (b (list 2 3) ($vau #ignore #ignore
              ($check equal? (a) (list 2 3)))))))
        ($let (((b1 a1) (make-keyed-dynamic-variable))
               ((b2 a2) (make-keyed-dynamic-variable)))
          (b1 1 ($lambda ()
            (b2 2 ($lambda ()
              (b1 3 ($lambda ()
                (b2 4 ($lambda ()
                  ($check equal? (a1) 3)
                  ($check equal? (a2) 4))))))))))
        ($let (((b1 a1) (make-keyed-dynamic-variable))
               ((b2 a2) (make-keyed-dynamic-variable))
               ((b3 a3) (make-keyed-dynamic-variable)))
          (b1 1 ($lambda ()
            (b2 2 ($lambda ()
              (b3 3 ($lambda ()
                (b1 4 ($lambda ()
                  (b2 5 ($lambda ()
                    (b3 6 ($lambda ()
                      ($check equal? (a1) 4)
                      ($check equal? (a2) 5)
                      ($check equal? (a3) 6)))))))))))))))

      ($test-group signal-error
          ((cite (kernel-report 10 1 1)
                 "If the call to /a/ is not within the dynamic extent of
                 any call to /b/, an error is signaled.")
           (number 2))
        ($check-error ((cadr (make-keyed-dynamic-variable))))
        ($let (((b1 a1) (make-keyed-dynamic-variable))
               ((b2 a2) (make-keyed-dynamic-variable)))
          (b1 1 ($lambda ()
            ($check-error (a2))))))))

  ($test-group interaction
      ((plan extend-continuation guard-dynamic-extent))

    ($test-group extend-continuation
        ((number 2))
      ($define! (b a)
        (make-keyed-dynamic-variable))
      ($define! pass
        ($lambda back
          (apply-continuation back (a))))
      ($define! go
        ($lambda (there)
          ($let/cc here
            (apply-continuation there here))))
      ($define! (k1 k2)
        ($let ((state (make-kernel-standard-environment)))
          (b 420 ($lambda () ($let/cc k1 ($set! state k1 k1))))
          (b 314 ($lambda () ($let/cc k2 ($set! state k2 k2))))
          ($remote-eval (list k1 k2) state)))
      ($define! r1 (go (extend-continuation k1 pass)))
      ($define! r2 (go (extend-continuation k2 pass)))
      ($check equal? r1 420)
      ($check equal? r2 314))

    ($test-group guard-dynamic-extent
        ((number 4))

      ($define! (b a)
        (make-keyed-dynamic-variable))

      (b 123 ($lambda ()
               (guard-dynamic-extent
                 ()
                 ($lambda ()
                   (b 234
                      ($lambda ()
                        ($check equal? (a) 234)
                        some-undefined-symbol)))
                 (list (list root-continuation
                             ($lambda (#ignore divert)
                               ($check equal? (a) 123)
                               (divert)))))))
      ($let/cc done
        (b 345 ($lambda ()
                 ($define! re-enter
                   (guard-dynamic-extent
                     (list (list root-continuation
                                 ($lambda (#ignore divert)
                                   ($check equal? (a) 345)
                                   (apply-continuation done #inert))))
                     ($lambda ()
                       (b 456
                          ($lambda ()
                            ($check equal? (a) 456)
                            ($let/cc here here))))
                     ()))
                 (apply-continuation re-enter ())))))))
