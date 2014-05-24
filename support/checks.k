;;;
;;; checks.k
;;;
;;; High-level test combiners.
;;;
;;;   (eval-protect OBJ ENV) => (EVENT VALUE)
;;;
;;;     Evaluate OBJ in ENV, protecting the caller from errors
;;;     occuring during the evaluation. The applicative returns
;;;     a list. The first element describes how the evaluation
;;;     terminated, the second element contains the actual result.
;;;
;;;       (event-return VALUE)
;;;       (event-error VALUE)
;;;       (event-exit VALUE)
;;;
;;;   ($check FORM)
;;;
;;;     Evaluate FORM in the dynamic environment and record the result
;;;     in the current test group.
;;;
;;;   ($check EQV? FORM-1 FORM-2)
;;;
;;;     Evaluate FORM-1 and FORM-2 in the dynamic environment and
;;;     compare using the binary predicate EQV?. Record the result
;;;     in the current test group.
;;;
;;;   ($eval-table (SUT REF) ...)
;;;
;;;     Evaluate SUT and REF in a standard environment. Pass if the
;;;     results are equal?, fail otherwise.
;;;
;;;   ($check-effects EXPR LOG)
;;;
;;;     Check order of side effects in EXPR. Evaluate EXPR in
;;;     a standard environment extended with an applicative named |eff|.
;;;
;;;       (eff LOG-VALUE RETURN-VAL) => RETURN-VALUE
;;;
;;;     Ignore the result of evaluation and compare LOG with a list
;;;     of LOG-VALUEs passed to (eff ...).
;;;

($provide! (event-return event-error event-exit
            event? event->string)

  ($define! (make-event event? event->string)
    (make-encapsulation-type))

  ($define! event-return (make-event "return"))
  ($define! event-error (make-event "error"))
  ($define! event-exit (make-event "exit")))

($provide! (eval-protect)

  ($define! entry-guards
    (list (list root-continuation
                ($lambda (obj divert)
                  (error "eval-protect re-entered")))))

  ($define! exit-guards
    (list (list error-continuation
                ($lambda (obj divert)
                  (divert event-error obj)))
          (list root-continuation
                ($lambda (obj divert)
                  (divert event-exit obj)))))

  ($define! eval-protect
    ($lambda (x e)
      (guard-dynamic-extent
        entry-guards
        ($lambda () (list event-return (eval x e)))
        exit-guards))))

($define! $check
  ($vau args denv
    ($cond
      ((null? (cdr args))
        ($define! (expr) args)
        (test-result! #ignore
                      (equal? (eval-protect expr denv)
                              (list event-return #t))
                     expr))
      (#t
        ($define! (eqv? x y) args)
        ($define! (xe xr) (eval-protect x denv))
        ($define! (ye yr) (eval-protect y denv))
        (test-result! #ignore
                      ($and? (equal? event-return xe)
                             (equal? event-return ye)
                             ((eval eqv? denv) xr yr))
                      eqv? x y
                      (list xe xr)
                      (list ye yr))))))

($define! $eval-table
  ($vau items denv
    ($let ((env (make-kernel-standard-environment)))
      (for-each
        ($lambda ((expression expected-result))
          ($let ((sut (eval-protect expression env))
                 (ref (eval-protect expected-result env)))
            (test-result! #ignore (equal? sut ref) expression)))
        items))))

($define! $check-effects
  ($vau (expression expected-effects) denv
    ($letrec ((exec-env (make-kernel-standard-environment))
              (log      ())
              (log-env  (get-current-environment)))
      ($set! exec-env eff
        ($lambda (log-value return-value)
          ($set! log-env log (cons log-value log))
          return-value))
      (eval-protect expression exec-env) ; ignore result
      (test-result! #ignore (equal? (reverse log) expected-effects) expression))))
