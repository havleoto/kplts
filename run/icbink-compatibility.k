;;;
;;; icbink-compatibility.k
;;;
;;; Compatibility layer for icbink. See also icbink.sh.
;;;

;; icbink's $sequence does not allow ()
($define! $sequence
  ($let ((icbink:$sequence $sequence))
    ($vau args denv
      ($if (null? args)
        #inert
        (eval (cons icbink:$sequence args) denv)))))

($define! $provide!
  ($vau (names . body) denv
    ($let ((xenv (make-environment denv)))
      (eval (cons $sequence body) xenv)
      (eval (list $set! denv names (cons list names)) xenv))))

($define! $import!
  ($vau (exp . symbols) env
    (eval (list $set! env symbols (cons list symbols))
          (eval exp env))))

($define! $let-redirect
  ($vau (exp bindings . body) env
    (eval (list* (eval (list* $lambda (map car bindings) body)
                       (eval exp env))
                 (map cadr bindings))
          env)))

($define! $bindings->environment
  ($vau bindings denv
    (eval (list $let-redirect (make-environment)
                              bindings
                              (list get-current-environment))
          denv)))

($define! $binds?
  ($vau (exp . ss) denv
    (guard-dynamic-extent
      ()
      ($lambda ()
        (eval (cons list ss) (eval exp denv))
        #t)
      (list (list error-continuation
        ($lambda (#ignore divert)
          (apply divert #f)))))))

($define! length
  ($lambda (xs)
    ($cond
      ((null? xs) 0)
      ((pair? xs) (+ 1 (length (cdr xs))))
      (#t         (error "length: not a list" xs)))))

($define! positive?
  ($lambda xs
    (apply <=? (cons 0 xs))))

($define! append
  ($lambda xs
    ($cond
      ((null? xs)
        ())
      ((null? (car xs))
        (apply append (cdr xs)))
      (#t
        (cons (caar xs) (apply append (cons (cdar xs) (cdr xs))))))))

;;
;; Definition of guard-dynamic-extent from Kernel Report does not seem to work
;; in icbink...

(println "Warning(run/icbink-compatibility.k): incomplete guard-dynamic-extent, entry guards ignored!")
($define! guard-dynamic-extent
  (wrap ($vau (#ignore combiner exit-guards) env
    ($let/cc cont
      (apply-continuation
        (extend-continuation
          (guard-continuation
            ()
            cont
            exit-guards)
          ($lambda #ignore
            (apply combiner () env)))
        ())))))

#;($define! guard-dynamic-extent
  (wrap ($vau (entry-guards combiner exit-guards) env
    ($let ((local (get-current-environment)))
      ($let/cc bypass
        ($set! local bypass bypass)
        (apply-continuation
          (car ($let/cc cont
                 ($set! local enter-through-bypass
                   (continuation->applicative cont))
                 (list bypass)))
          #inert)))
    ($let/cc cont
      (enter-through-bypass
        (extend-continuation
          (guard-continuation
            (cons (list bypass ($lambda (v . #ignore) v))
                  entry-guards)
            cont
            exit-guards)
          ($lambda #ignore
            (apply combiner () env))))))))


($define! error
  (wrap ($vau args denv
    (eval (cons + args) denv))))

($define! test-print println)

($define! appropriate-number-of-calls 1000)

(load "../support/utils.k")
(load "../support/checks.k")
(load "../support/fuzz.k")
(load "../support/hierarchy.k")
(load "../support/random.k")
(load "suite.k")
