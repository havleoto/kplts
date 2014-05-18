;;;
;;; booleans.k
;;;
;;; Test of boolean features.
;;;

($test-group booleans
    ((cite (kernel-report 6 1)))

  ($test-group not?
      ((cite (kernel-report 6 1 1))
       (require-standard-bindings not?)
       (plan normal-operation error-handling))
    ($test-group normal-operation
      ((number 2))
      ($eval-table
        ((not? #f) #t)
        ((not? #t) #f))))

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
        ((and? #f #f) #f))))

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
        ((or? #f #f) #f))))

  ($test-group $and?
      ((cite (kernel-report 6 1 4))
       (require-standard-bindings $and?)
       (plan normal-operation error-handling))
    ($test-group normal-operation
        ((number 7))
      ($eval-table
        (($and?)       #t)
        (($and? #t)    #t)
        (($and? #f)    #f)
        (($and? #t #t) #t)
        (($and? #t #f) #f)
        (($and? #f #t) #f)
        (($and? #f #f) #f))))

  ($test-group $or?
      ((cite (kernel-report 6 1 4))
       (require-standard-bindings $or?)
       (plan normal-operation error-handling))
    ($test-group normal-operation
        ((number 7))
      ($eval-table
        (($or?)       #t)
        (($or? #t)    #t)
        (($or? #f)    #f)
        (($or? #t #t) #t)
        (($or? #t #f) #f)
        (($or? #f #t) #f)
        (($or? #f #f) #f)))))
