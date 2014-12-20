;;;
;;; promises.k
;;;
;;; Test lazy evaluation features from Kernel Report chapter 9.
;;;

($test-group promises
    ((cite (kernel-report 9))
     (plan encapsulation equality promise? force $lazy memoize
           kernel-report-examples))

  ($test-group encapsulation
      ((cite (kernel-report 9)
             "The Kernel data type promise is encapsulated.")
       (number 10))
    ($eval-table
      ((null? ($lazy ()))                               #f)
      ((boolean? ($lazy #t))                            #f)
      ((number? ($lazy 1))                              #f)
      ((string? ($lazy "x"))                            #f)
      ((pair? ($lazy (list 1)))                         #f)
      ((continuation? ($lazy root-continuation))        #f)
      ((environment? ($lazy (get-current-environment))) #f))
    ($check-error ($if ($lazy #t) 1 2))
    ($check-error (car ($lazy 1)))
    ($check-error (+ 1 ($lazy 1))))

  ($test-group equality
      ((plan eq? equal?))

    ($test-group eq?
        ((cite (kernel-report 9)
              "eq? [...] to distinguish promises if they can exhibit
               different behavior")
         (require-standard-bindings eq?)
         (number 4))
      ($check (not? (eq? ($lazy 1) ($lazy 2))))
      ($check (not? (eq? ($lazy 1) (memoize 2))))
      ($let ((p ($lazy 1))) ($check eq? p p))
      ($let ((p ($lazy 1))) ($check (not? (eq? p (force p))))))

    ($test-group equal?
        ((cite (kernel-report 9)
               "Two promises are equal? iff they are eq?")
         (require-standard-bindings eq?)
         (number 4))
      ($check (not? (equal? ($lazy 1) ($lazy 2))))
      ($check (not? (equal? ($lazy 1) (memoize 2))))
      ($let ((p ($lazy 1))) ($check equal? p p))
      ($let ((p ($lazy 1))) ($check (not? (equal? p (force p)))))))

  ($test-group promise?
      ((cite (kernel-report 9 1 1)
             "primitive type predicate for type promise")
       (number 15))
    ($eval-table
      ((promise? ($lazy 1))          #t)
      ((promise? (memoize 1))        #t)
      ((promise? #inert)             #f)
      ((promise? #ignore)            #f)
      ((promise? 1)                  #f)
      ((promise? ((unwrap list*) x)) #f)
      ((promise? "abc")              #f)
      ((promise? #t)                 #f)
      ((promise? #f)                 #f)
      ((promise? ())                 #f)
      ((promise? (list 1 2))         #f)
      ((promise? promise?)           #f)
      ((promise? $if)                #f)
      ((promise? (make-environment)) #f)
      ((promise? root-continuation)  #f)))

  ($test-group force
      ((cite (kernel-report 9 1 2))
       (plan promise not-promise error-handling))

    ($test-group promise
        ((cite (kernel-report 9 1 2)
               "If /object/ is a promise, applicative force
                returns the value determined by promise.")
         (number 3))
      ($eval-table
        ((force ($lazy 1))          1)
        ((force ($lazy (list 1 2))) (list 1 2))
        ((force (memoize ()))       ())))

    ($test-group not-promise
        ((cite (kernel-report 9 1 2)
               "otherwise, it returns /object/")
         (number 3))
      ($eval-table
        ((force 1) 1)
        ((force ()) ()))
      ($let ((e (make-environment)))
        ($check equal? (force (cons 1 e)) (cons 1 e))))

    ($test-group error-handling
        ((number 10))
      ($fuzz-applicative 10 force
        ($lambda (x) ($and? (finite-list? x) (equal? (length x) 1)))
        () (1) (1 2))))

  ($test-group $lazy
      ((cite (kernel-report 9 1 3))
       (plan dynamic-environment evaluate-when-forced
             favor-first-result force-result
             force-iteratively unbounded-sequence
             distinct-promises error-handling))

    ($test-group dynamic-environment
        ((cite (kernel-report 9 1 3)
               "expression is evaluated in the dynamic environment
                of the constructing call to $lazy")
         (number 3))
      ($let* ((x 1)
              (y 2)
              (p1 ($let ((x 3)) ($lazy (+ x y))))
              (p2 ($let ((x 4)) ($lazy (+ x y)))))
        ($check equal? (force p1) 5)
        ($check equal? (force p2) 6))
      ($check equal?
              (force ($lazy (get-current-environment)))
              (get-current-environment)))

    ($test-group evaluate-when-forced
        ((cite (kernel-report 9 1 3)
               "When the promise is forced, if a value has not previously been
                determined for it, /expression/ is evaluated")
         (number 5))
      ($letrec ((n 0)
                (e (get-current-environment))
                (p ($lazy ($set! e n 1)))
                (q ($lazy ($set! e n 2))))
        ($check equal? n 0)
        ($check equal? (force q) #inert)
        ($check equal? n 2)
        ($check equal? (force p) #inert)
        ($check equal? n 1)))

    ($test-group favor-first-result
        ((cite (kernel-report 9 1 3)
               "If, when the evaluation returns a result, a value is
                found to have been determined for the promise during
                the evaluation, the result is discarded in favor
                of the previously determined value")
         (number 1))
      ($check equal?
        ($letrec ((n 0)
                  (e (get-current-environment))
                  (p ($lazy ($if (equal? n 4)
                                3
                                ($sequence ($set! e n (+ n 2))
                                           (+ 1 (force p)))))))
          (force p))
        3))

    ($test-group force-result
        ((cite (kernel-report 9 1 3)
               "evaluation [...] result is forced, and the value returned
               by that forcing becomes the value determined by the promise")
         (number 2))
      ($eval-table
        ((force ($lazy ($lazy 1)))   1)
        ((force ($lazy (memoize 2))) 2)))

    ($test-group force-iteratively
        ((cite (kernel-report 9 1 3)
               "Forcing [...] may cause a sequential series of evaluations,
                each of which returns a promise that is forced and thus
                initiates the next evaluation in the series.")
         (number 2))
      ($eval-table
        ((force ($lazy ($lazy ($lazy 1))))   1)
        ((force ($lazy ($lazy (memoize 2)))) 2)))

    ($test-group unbounded-sequence
        ((cite (kernel-report 9 1 3)
               "must support series of this kind with unbounded length")
         (number 3))
      ($define! f
        ($lambda (n)
          ($if (<=? n 1)
               n
               ($lazy (+ n (force (f (- n 1))))))))
      ($check equal? (force (f 10))       55)
      ($check equal? (force (f 100))    5050)
      ($check equal? (force (f 1000)) 500500))

    ($test-group distinct-promises
        ((cite (kernel-report 9 1 3)
               "Distinct promises [...] even if they do represent
                evaluation of the same expression in the same environment,
                [...] actual evaluation will take place the first time each
                of them is forced")
         (number 15))
      ($letrec ((n 0)
                (e (get-current-environment))
                (f ($lambda () ($set! e n (+ n 1)) n))
                (p ($lazy (f)))
                (q ($lazy (f)))
                (r ($lazy (f))))
        ($check equal? n 0)
        ($check equal? (force q) 1)
        ($check equal? n 1)
        ($check equal? (force q) 1)
        ($check equal? n 1)
        ($check equal? (force r) 2)
        ($check equal? n 2)
        ($check equal? (force q) 1)
        ($check equal? n 2)
        ($check equal? (force p) 3)
        ($check equal? n 3)
        ($check equal? (force q) 1)
        ($check equal? n 3)
        ($check equal? (force r) 2)
        ($check equal? n 3)))

    ($test-group error-handling
        ((number 3))
      ($check-error ($lazy))
      ($check-error ($lazy #t #f))
      ($check-error ($lazy . #ignore))))

  ($test-group memoize
      ((cite (kernel-report 9 1 4))
       (plan object-not-promise object-is-promise error-handling))

    ($test-group object-not-promise
        ((cite (kernel-report 9 1 4)
               "Whenever the promise is forced, it determines /object/.")
         (number 3))
      ($eval-table
        ((force (memoize 1))          1)
        ((force (memoize (list 2 3))) (list 2 3))
        ((force (memoize #inert))     #inert)))

    ($test-group object-is-promise
        ((cite (kernel-report 9 1 4)
               "allows a promise to be the result of lazy computation")
         (number 7))
      ($eval-table
        ((promise? (memoize ($lazy 1)))                             #t)
        ((promise? (force (memoize ($lazy 2))))                     #t)
        ((force (force (memoize ($lazy 3))))                         3)
        ((promise? (memoize (memoize (memoize 4))))                 #t)
        ((promise? (force (memoize (memoize (memoize 5)))))         #t)
        ((promise? (force (force (memoize (memoize (memoize 6)))))) #t)
        ((force (force (force (memoize (memoize (memoize 7))))))     7)))

   ($test-group error-handling
        ((number 10))
      ($fuzz-applicative 10 memoize
        ($lambda (x) ($and? (finite-list? x) (equal? (length x) 1)))
        () (1) (1 2))))

  ($test-group kernel-report-examples
      ((cite (kernel-report 9 1 3))
       (plan get-count stream-filter))

    ($test-group get-count
        ((number 3))
      ($provide! (get-count p)
        ($define! count 5)
        ($define! get-count ($lambda () count))
        ($define! p
          ($let ((self (get-current-environment)))
            ($lazy
              ($if (<=? count 0)
                count
                ($sequence
                  ($set! self count (- count 1))
                  (force p)
                  ($set! self count (+ count 2))
                  count))))))
      ($check equal? (get-count) 5)
      ($check equal? (force p) 0)
      ($check equal? (get-count) 10))

  ($test-group stream-filter
      ((number 1))
    ($define! stream-filter
      ($lambda (p? s)
        ($lazy
        ($let ((v (force s)))
          ($if (null? v)
                v
                ($let ((s (stream-filter p? (cdr v))))
                  ($if (p? (car v))
                    (cons (car v) s)
                    s)))))))
    ($define! from
      ($lambda (n)
        ($lazy (cons n (from (+ n 1))))))
    ($define! result
      (force
        (stream-filter ($lambda (n) (=? n 100))
                       (from 0))))
    ($check equal? (car result) 100))))
