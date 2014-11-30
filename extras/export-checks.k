;;;
;;; export-checks.k
;;;
;;; Export self-contained checks from the test suite.
;;;
;;; The script prints a certain subset of the checks defined in the test
;;; suite, discarding the hierarchy of test groups. The output can be
;;; edited by hand and used to test interpreters that cannot run the
;;; full test suite.
;;;
;;; usage [in kplts/tests]:
;;;
;;;   klisp ../extras/export-checks.k > CHECKS.k
;;;   $MY-INTERPRETER < CHECK.k
;;;

($define! stdenv (make-kernel-standard-environment))

;; load helpers from support/

($define! test-print
  ($lambda args
    (for-each
      ($lambda (x) (write-char #\space) (display x))
      args)
    (newline)))

($define! appropriate-number-of-calls 10)

(load "../support/utils.k")
(load "../support/random.k")

;; replace hierarchy.k

($provide! ($test-group $test-suite)

  ($define! (bind-path access-path)
    (make-keyed-dynamic-variable))

  ($define! $test-group
    ($vau (name metadata . body) denv
      (bind-path (cons name (access-path))
        ($lambda ()
          (test-print ";" (reverse (access-path)))
          (eval (list* $let () body) denv)))))

  ($define! $test-suite
    ($vau args denv
      (bind-path () ($lambda () (eval (cons $test-group args) denv))))))

($define! test-result! ($lambda #ignore #inert))

;; replace checks.k

($define! eval-protect
  ($lambda #ignore #inert))

;;
;; $eval-table evaluates the arguments in a standard environment. The
;; arguments can be safely exported.
;;

($define! $eval-table
  ($vau items denv
    (for-each
      ($lambda ((lhs rhs))
        (write (list ($quote $check-equal) lhs rhs))
        (newline))
      items)))

;;
;; $check and $check-error evaluate arguments in the dynamic environment.
;; The checks can be exported only if all subexpressions have the same
;; meaning in the standard environment.
;;

($provide! ($check $check-error)

  ($define! equivalent-eval
    ($lambda (x e1 e2 ttl abort)
      ($cond
        ((symbol? x)
          ($define! b1 (binds? e1 x))
          ($define! b2 (binds? e2 x))
          ($cond
            (($and? b1 b2)
              ($define! y1 (eval x e1))
              ($define! y2 (eval x e2))
              ($unless (eq? y1 y2) (abort))
              y1)
            (#t
              (abort))))
        ((pair? x) 
          ($unless ($and? (symbol? (car x))
                          (finite-list? (cdr x)))
            (abort))
          ($define! f (equivalent-eval (car x) e1 e2 (- ttl 1) abort))
          ($unless (applicative? f) (abort))
          (for-each
            ($lambda (y) (equivalent-eval y e1 e2 (- ttl 1) abort))
            (cdr x)))
        (($or? (environment? x) (combiner? x))
          (abort))
        (#t
          x))))

  ($define! equivalent-eval?
    ($lambda (x e1 e2)
      ($let/cc k
        (equivalent-eval x e1 e2 10 ($lambda () (apply-continuation k #f)))
        #t)))

  ($define! $check
    ($vau args denv
      ($cond
        ((=? (length args) 1)
          ($define! (arg) args)
          ($when (equivalent-eval? arg denv stdenv)
            (write-simple (list ($quote $check-true) arg))
            (newline)))
        ((=? (length args) 3)
          ($define! (eqv lhs rhs) args)
          ($when ($and? (equal? eqv ($quote equal?))
                    (equivalent-eval? lhs denv stdenv)
                    (equivalent-eval? rhs denv stdenv))
            (write-simple (list ($quote $check-equal) lhs rhs))
            (newline))))))

  ($define! $check-error
    ($vau (arg) denv
      ($when (equivalent-eval? arg denv stdenv)
        (write-simple (list ($quote $check-error) arg))
        (newline)))))

;;
;; $check-effects depends on mutable state and it is not exported
;;

($define! $check-effects
  ($vau #ignore #ignore #inert))

;;
;; export $fuzz-operative
;;

($let ((parent-env (get-current-environment)))

  ($define! fuzz-env
    (make-environment parent-env))

  ($define! (bind-uneval access-uneval)
    (make-keyed-dynamic-variable))

  ($define! global-uneval
    (apply append (map
      ($lambda (s)
        ($define! v (eval s parent-env))
        ($define! a (cons v s))
        (cons a
              ($if (applicative? v)
                 (list (cons (unwrap (eval s parent-env))
                             (list ($quote unwrap) s)))
                 ())))
      ((unwrap list)
        $quote $sequence
        apply cons list))))

  ($define! export-form
    ($lambda (x)
      ($cond
        ((pair? x)
          ($if (eq? (car x) $quote)
            (export-quote x)
            (cons (export-form (car x)) (export-form (cdr x)))))
        ((combiner? x)
          ($define! v (assoc x (access-uneval)))
          ($if (pair? v) (cdr v) x))
        ((environment? x)
          ($quote (get-current-environment)))
        (#t
          x))))

  ($define! export-quote
    ($lambda (x)
      ($cond
        ((finite-list? x)
          (cons ($quote list) (map export-quote x)))
        ((pair? x)
          (list ($quote cons) (export-quote (car x)) (export-quote (cdr x))))
        ((combiner? x)
          ($define! v (assoc x (access-uneval)))
          ($if (pair? v) (cdr v) x))
        ((environment? x)
          ($quote (get-current-environment)))
        (#t
          x))))

  ($set! fuzz-env eval-protect
    ($lambda (form #ignore)
      (write (list ($quote $check-error) (export-form form)))
      (newline)
      (list #inert #inert)))

  ($set! fuzz-env event-return #inert)
  ($set! fuzz-env event-error #inert)
  ($set! fuzz-env event-exit #inert)

  (eval (list load "../support/fuzz.k") fuzz-env)

  ($set! parent-env $fuzz-applicative
    ($vau args denv
      ($define! (count f valid-ptree? . ptree-samples) args)
      (bind-uneval
        (append (list (cons (eval f denv) f)
                      (cons (unwrap (eval f denv)) (list ($quote unwrap) f)))
                global-uneval)
        ($lambda ()
          (eval (cons ($remote-eval $fuzz-applicative fuzz-env) args)
                denv))))))


;; ignore errors if some files are missing

($define! load
  ($let ((load-0 load))
    (wrap ($vau (file) denv
      (guard-dynamic-extent
        ()
        ($lambda () (eval (list load-0 file) denv))
        (list (list error-continuation
                    ($lambda (eobj divert)
                      (test-print "; WARNING: " file ", error: "
                        (error-object-message eobj)
                        (error-object-irritants eobj))
                      (apply divert #inert)))))))))

(test-print ";;")
(test-print ";; ----- support definitions, change as appropriate for your intepreter ---")
(test-print ";;")

(for-each
  ($lambda (form)
    (write form)
    (newline))
  ((unwrap list)
    ($define! pass
      ($lambda x (write (cons "PASS" x)) (newline)))

    ($define! fail
      ($lambda x (write (cons "FAIL" x)) (newline)))

    ($define! $quote
      ($vau (x) #ignore x))

    ($define! $check-true
      ($vau (x) e
        ($if (eval x e)
          (pass x)
          (fail x))))

    ($define! $check-equal
      ($vau (x y) e
        ($if (equal? (eval x e) (eval y e))
          (pass x y)
          (fail x y))))

    ($define! $check-error
      ($vau (x) e
        ($if (guard-dynamic-extent
              ()
              ($lambda () (eval x e) #f)
              (list (list error-continuation ($lambda (o d) (apply d #t)))))
          (pass x)
          (fail x))))))

(test-print ";;")
(test-print ";; ----- tests ------ ")
(test-print ";;")

;; run the test suite

(load "suite.k")
