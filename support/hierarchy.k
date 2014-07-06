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
;;;     (number N)
;;;
;;;       Declare number of subtests in advance.
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
;;;       TODO: Do not fail, but skip?
;;;
;;;     (require-modules . SYMBOLs)
;;;
;;;       Skip the test, if some of the SYMBOLs is not present in the
;;;       list supported-modules declared by the interpreter under test.
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
;;; (warn . ARGUMENTS)
;;;
;;;   Print warning message.
;;;
;;; (kernel-module? . OBJECTs)
;;;
;;;   Return #t if each of OBJECTs is a symbol denoting a module
;;;   defined in the Kernel Report.
;;;
;;; (supported-module? . SYMBOLs)
;;;
;;;   Return #t if the interpreter under test claims support of
;;;   all modules denoted by SYMBOLs.
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
                     (global-skip-counter 0)
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
          ($import! globals global-pass-counter global-fail-counter
                            global-skip-counter global-warn-counter)
          (test-print "Total:" global-pass-counter "pass,"
                      global-fail-counter "fail,"
                      global-skip-counter "skipped,"
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
                (skip #f)
                (local-pass-counter 0)
                (local-fail-counter 0))))
          (bind-current-test
            test-env
            ($lambda ()
              ($import! (access-current-test) path)
              (apply test-print (cons ";" (reverse path)))
              ($unless (run-path? ($remote-eval run-only test-options)
                                 (reverse path))
                (skip-current-test!))
              (eval-body meta pre-env)
              ($unless ($remote-eval skip (access-current-test))
                (eval-body body)
                (eval-body meta post-env))))
          ($when ($binds? test-env summary)
            ($import! test-env summary)
            (test-result! name summary)))
        (list (list root-continuation
                    ($lambda (obj divert)
                      (test-result! name #f obj)
                      (apply divert #inert)))))))

  ($define! run-path?
    ($lambda (run-only path)
      ($or? (null? run-only)
            (null? path)
            ($and? (equal? (car run-only) (car path))
                   (run-path? (cdr run-only) (cdr path))))))

  ($define! skip-current-test!
    ($lambda ()
      ($define! our (access-current-test))
      ($import! our globals path)
      ($set! our skip #t)
      ($increment! globals global-skip-counter)
      (test-print "Skipped:" (car path))))

  ($define! no-op
    ($vau #ignore #ignore #inert))

  ($define! pre-env
    ($bindings->environment
      (require-standard-bindings
        ($vau args denv
          ($let ((env (make-kernel-standard-environment)))
            ($unless (eval (list* $binds? env args) env)
              (error "Required bindings not implemented." args)))))
      (require-modules
        ($vau args denv
          ($unless (apply supported-module? args)
            (skip-current-test!))))
      (cite no-op)
      (plan no-op)
      (number no-op)))

  ($define! post-env
    ($bindings->environment
      (require-standard-bindings no-op)
      (require-modules no-op)
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

($provide! (kernel-module? supported-module?)

  ($define! list->predicate
    ($lambda (xs)
      ($lambda ys
        (apply and?
               (map ($lambda (y) (member? y xs))
                    ys)))))

  ;; All modules from the kernel report.
  ;;  TODO: list only optional ones?
  ;;
  ($define! kernel-module?
    ((unwrap list->predicate)
     (booleans
      equivalence-under-mutation
      equivalence-up-to-mutation
      symbols
      control
      pairs-and-lists
      pair-mutation
      environments
      environment-mutation
      combiners
      continuations
      encapsulations
      promises
      keyed-dynamic-variables
      keyed-static-variables
      numbers
        integer rational inexact real complex
      strings
      characters
      ports)))

  ;; The list of supported optional modules is defined by the compatibility layer.
  ;;
  (test-print ";" "The system under test claims support of the optional modules:")
  (for-each
    ($lambda (m)
      ($if (kernel-module? m)
        (test-print ";  " m)
        (test-print ";  " m "(this is not a standard module, check supported-modules)")))
    supported-modules)

  ;; Make a copy to catch accidental mutation, if possible.
  ;;
  ($define! supported-module?
    (list->predicate
      ($if ($binds? (get-current-environment) copy-es-immutable)
        (copy-es-immutable supported-modules)
        supported-modules))))

;; Print test options.
;;
(test-print "; Test run options:")
(for-each
  ($lambda (name) (test-print ";  " name (eval name test-options)))
  ((unwrap list) run-only print-evaluations))



