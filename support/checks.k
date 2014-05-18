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
;;;   ($check FORM ...)
;;;
;;;     TODO
;;;
;;;   ($eval-table (SUT REF) ...)
;;;
;;;     Evaluate SUT and REF in a standard environment. Pass if the
;;;     results are equal?, fail otherwise.
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
                      ($and? (eq? event-return xe ye)
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
