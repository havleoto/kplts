;;;
;;; booleans.k
;;;
;;; Test of boolean features.
;;;

($test-group booleans
    ((cite (kernel-report 6 1))
     (plan boolean? not? and? or? $and? $or?))

  ($test-group boolean?
      ((cite (kernel-report 4 1 1))
       (plan normal-operation error-handling))
    ($test-group normal-operation
        ((number 7))
      ($eval-table
        ((boolean?) #t)
        ((boolean? #t) #t)
        ((boolean? #f) #t)
        ((boolean? 0) #f)
        ((boolean? boolean?) #f)
        ((boolean? #t #f) #t)
        ((boolean? #t 0) #f)))
    ($test-group error-handling
        ((number 20))
      ($fuzz-applicative 20 boolean?
        ($lambda (x) (finite-list? x))
        (#t)
        (#t #t)
        (#t #t #t))))

  ($test-group not?
      ((cite (kernel-report 6 1 1))
       (require-standard-bindings not?)
       (plan normal-operation error-handling))
    ($test-group normal-operation
        ((number 2))
      ($eval-table
        ((not? #f) #t)
        ((not? #t) #f)))
    ($test-group error-handling
        ((number 20))
      ($fuzz-applicative 20 not?
        ($lambda (x) ($and? (pair? x) (null? (cdr x)) (boolean? (car x))))
        (#f))))

  ($test-group and?
      ((cite (kernel-report 6 1 2))
       (require-standard-bindings and?)
       (plan normal-operation error-handling))
    ($test-group normal-operation
        ((number 7))
      ($eval-table
        ((and?)       #t)
        ((and? #t)    #t)
        ((and? #f)    #f)
        ((and? #t #t) #t)
        ((and? #t #f) #f)
        ((and? #f #t) #f)
        ((and? #f #f) #f)))
    ($test-group error-handling
        ((number 20))
      ($fuzz-applicative 20 and?
        ($lambda (x) ($and? (finite-list? x) (apply boolean? x)))
        ()
        (#t)
        (#t #t)
        (#t #t #t))))

  ($test-group or?
      ((cite (kernel-report 6 1 3))
       (require-standard-bindings or?)
       (plan normal-operation error-handling))
    ($test-group normal-operation
        ((number 7))
      ($eval-table
        ((or?)       #f)
        ((or? #t)    #t)
        ((or? #f)    #f)
        ((or? #t #t) #t)
        ((or? #t #f) #t)
        ((or? #f #t) #t)
        ((or? #f #f) #f)))
    ($test-group error-handling
        ((number 20))
      ($fuzz-applicative 20 or?
        ($lambda (x) ($and? (finite-list? x) (apply boolean? x)))
        ()
        (#t)
        (#t #t)
        (#t #t #t))))

  ($test-group $and?
      ((cite (kernel-report 6 1 4))
       (require-standard-bindings $and?)
       (plan normal-operation short-circuit error-handling robust-error-handling))
    ($test-group normal-operation
        ((number 7))
      ($eval-table
        (($and?)       #t)
        (($and? #t)    #t)
        (($and? #f)    #f)
        (($and? #t #t) #t)
        (($and? #t #f) #f)
        (($and? #f #t) #f)
        (($and? #f #f) #f)))
    ($test-group short-circuit
        ((cite (kernel-report 6 1 4)
              "If an operand evaluates to false, no further operand
               evaluations are performed, and the operative returns false.")
         (number 2))
      ($check-effects
        ($and? (eff 1 #t) (eff 2 #f) (eff 3 #f))
        (1 2))
      ($check-effects
        ($and? (eff 1 #t) (eff 2 #t) (eff 3 #f) (eff 4 #t))
        (1 2 3)))
    ($test-group error-handling
        ((number 2))
      ($check-error ($and? . #t))
      ($check-error ($and? #t . #t)))
    ($test-group robust-error-handling
        ((number 2))
      ($check-error ($and? 1))
      ($check-error ($and? #t 1))))

  ($test-group $or?
      ((cite (kernel-report 6 1 5))
       (require-standard-bindings $or?)
       (plan normal-operation short-circuit error-handling robust-error-handling))
    ($test-group normal-operation
        ((number 7))
      ($eval-table
        (($or?)       #f)
        (($or? #t)    #t)
        (($or? #f)    #f)
        (($or? #t #t) #t)
        (($or? #t #f) #t)
        (($or? #f #t) #t)
        (($or? #f #f) #f)))
    ($test-group short-circuit
        ((cite (kernel-report 6 1 5)
              "If an operand evaluates to true, no further operand
               evaluations are performed, and the operative return true.")
         (number 2))
      ($check-effects
        ($or? (eff 1 #t) (eff 2 #f))
        (1))
      ($check-effects
        ($or? (eff 1 #f) (eff 2 #f) (eff 3 #t) (eff 4 #t))
        (1 2 3)))
    ($test-group error-handling
        ((number 2))
      ($check-error ($or? . #t))
      ($check-error ($or? #f . #f)))
    ($test-group robust-error-handling
        ((number 2))
      ($check-error ($or? 1))
      ($check-error ($or? #f 0)))))
