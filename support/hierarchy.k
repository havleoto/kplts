;;;
;;; hierarchy.k
;;;
;;; Define hierarchy of test groups.
;;;
;;; ($test-suite NAME META-DATA . BODY)
;;; ($test-group NAME META-DATA . BODY)
;;;
;;;   Define new test group NAME with some META-DATA. The test group
;;;   is implemented in BODY. The argument META-DATA may contain
;;;
;;;     (plan SUBGROUP-1 SUBGROUP-2 ... SUBGROUP-N)
;;;
;;;       Declare name of subtests in advance.
;;;
;;;     (cite REFERENCE . TEXTs)
;;;
;;;       Refer to the part of the specification relevant to the test.
;;;       The REFERENCE is of the form (kernel-report SECTION-NUMBER).
;;;       The TEXTs are optional.
;;;
;;;     (require-standard-bindings . SYMBOLs)
;;;
;;;       Skip the test, if not all SYMBOLs are implemented.
;;;
;;;   The top-level group should be declared using $test-suite. Other
;;;   groups should be declared using $test-group.
;;;
;;; (test-result! NAME RESULT . REST)
;;;
;;;   Record test result. The NAME is either #ignore or a symbol. The
;;;   RESULT is a boolean. True value means PASS, false value means
;;;   FAIL. The optional message REST is printed.
;;;
;;;   The applicative test-result! is used internally in higher-level
;;;   test combiners like $check and $eval-table.
;;;

($provide! ($test-suite $test-group test-result! warn)

  ($define! (bind-current-test access-current-test)
    (make-keyed-dynamic-variable))

  ($define! $test-suite
    ($vau args denv
      ($define! globals
        ($bindings->environment
                     (global-pass-counter 0)
                     (global-fail-counter 0)
                     (global-warn-counter 0)))
      (bind-current-test
        ($bindings->environment
          (path ())
          (globals globals)
          (results (make-environment))
          (ran ())
          (local-pass-counter 0)
          (local-fail-counter 0))
        ($lambda ()
          (eval (cons $test-group args) denv)
          ($import! globals global-pass-counter global-fail-counter global-warn-counter)
          (test-print "Total:" global-pass-counter "pass,"
                      global-fail-counter "fail,"
                      global-warn-counter "warnings.")))))

  ($define! $test-group
    ($vau (name meta . body) denv
      ($define! eval-body
        ($lambda (b . envs)
          (eval (cons $sequence b)
                (apply make-environment (append envs (list denv))))))
      (guard-dynamic-extent
        entry-guards
        ($lambda ()
          ($unless ($and? (finite-list? meta)
                          (apply pair? meta)
                          (apply symbol? (map car meta))
                          (apply binds? (cons pre-env (map car meta)))
                          (apply binds? (cons post-env (map car meta))))
            (error "Malformed $test-group form. Invalid metadata."))
          ($define! test-env
            ($let ()
              ($import! (access-current-test) path globals)
              ($bindings->environment
                (path (cons name path))
                (globals globals)
                (results (make-environment))
                (ran ())
                (local-pass-counter 0)
                (local-fail-counter 0))))
          (bind-current-test
            test-env
            ($lambda ()
              ($import! (access-current-test) path)
              (apply test-print (cons ";" (reverse path)))
              (eval-body meta pre-env)
              (eval-body body)
              (eval-body meta post-env)))
          ($when ($binds? test-env summary)
            ($import! test-env summary)
            (test-result! name summary)))
        (list (list root-continuation
                    ($lambda (obj divert)
                      (test-result! name #f obj)
                      (apply divert #inert)))))))

  ($define! no-op
    ($vau #ignore #ignore #inert))

  ($define! pre-env
    ($bindings->environment
      (require-standard-bindings
        ($vau args denv
          ($let ((env (make-kernel-standard-environment)))
            ($unless (eval (list* $binds? env args) env)
              (error "Required bindings not implemented." args)))))
      (cite no-op)
      (plan no-op)
      (number no-op)))

  ($define! post-env
    ($bindings->environment
      (require-standard-bindings no-op)
      (cite no-op)
      (plan ($vau args denv
              ($define! our (access-current-test))
              ($import! our results path ran)
              ($set! our summary
                (apply and?
                  (map
                    ($lambda (subtest)
                      ($cond ((binds? results subtest)
                               (eval subtest results))
                             (#t
                               (warn subtest "not tested!")
                               #t)))
                    args)))
              (for-each
                ($lambda (subtest)
                  ($when ($and? (symbol? subtest) (not? (member? subtest args)))
                    (warn subtest "tested but not planned!")))
                ran)))
      (number ($lambda (n)
                ($define! our (access-current-test))
                ($import! our local-pass-counter local-fail-counter)
                ($cond
                  ((positive? local-fail-counter)
                    ($set! our summary #f))
                  ((=? local-pass-counter n)
                    ($set! our summary #t))
                  (#t
                    (warn "passed" local-pass-counter "tests, but planned" n)))))))

  ($define! entry-guards
    (list (list root-continuation
                ($lambda (obj divert)
                  (error "$test-group re-entered")))))

  ($define! test-result!
    ($lambda (test-id result . rest)
      ($define! current-test (access-current-test))
      ($import! current-test path globals results ran)
      ($when (symbol? test-id)
        (set! results test-id result)
        ($set! current-test ran (cons test-id ran)))
      ($cond
        ((equal? result #t)
          ($increment! current-test local-pass-counter)
          ($increment! globals global-pass-counter)
          ;(apply test-print
           ;      (list* "PASS" (reverse (cons test-id path)) result rest))
           )
        ((equal? result #f)
          ($increment! current-test local-fail-counter)
          ($increment! globals global-fail-counter)
          (apply test-print
                 (list* "FAIL" (reverse (cons test-id path)) result rest))))))

  ($define! warn
    ($lambda args
      ($import! (access-current-test) globals)
      ($increment! globals global-warn-counter)
      (apply test-print (cons "Warning:" args)))))
