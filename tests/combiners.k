;;;
;;; combiners.k
;;;
;;; Test Kernel Language combiner features.
;;;

($test-group combiners
    ((cite (kernel-report 4 10))
     (plan immutability
           equality
           $vau
           $lambda
           wrap
           unwrap))
  ($let (((qx qy qz) ((unwrap list) x y z)))
    ($test-group immutability
        ((cite (kernel-report 4 10)
              "All combiners are immutable.")
        (require-modules pair-mutation)
        (plan mutate-vau-ptree mutate-formals mutate-body))
      ($test-group mutate-vau-ptree
          ((number 4))
        ($let* ((form       (list $vau (list qy qx) qz (list list qx qy qz)))
                (comb       (eval form (make-kernel-standard-environment)))
                (env        (make-environment))
                (res1       (eval-protect (list comb 1 2) env))
                (#ignore    (set-car! (cdr form) (cons qy qx)))
                (res2       (eval-protect (list comb 3 4) env))
                (#ignore    (set-car! (cddr form) #ignore))
                (res3       (eval-protect (list comb 5 6) env))
                (#ignore    (set-car! (cdddr form) #inert))
                (res4       (eval-protect (list comb 7 8) env)))
          ($check equal? res1 (list event-return (list 2 1 env)))
          ($check equal? res2 (list event-return (list 4 3 env)))
          ($check equal? res3 (list event-return (list 6 5 env)))
          ($check equal? res4 (list event-return (list 8 7 env)))))
      ($test-group mutate-vau-formals
          ((cite (kernel-report 4 10 3)
                "When the $vau operative constructs a compound operative,
                  it stores in that compound operative references to [...]
                  an immutable copy of the evaluation structure of <formals>")
          (number 2))
        ($let* ((formals (list qx qy))
                (body    (list list qy qx))
                (comb    (eval (list $vau formals #ignore body)
                              (make-kernel-standard-environment)))
                (env     (make-environment))
                (res1    (eval-protect (list comb 1 2) env))
                (#ignore (set-car! formals ($quote z)))
                (res2    (eval-protect (list comb 3 4) env)))
          ($check equal? res1 (list event-return (list 2 1)))
          ($check equal? res2 (list event-return (list 4 3)))))
      ($test-group mutate-vau-body
          ((cite (kernel-report 4 10 3)
                "When the $vau operative constructs a compound operative,
                  it stores in that compound operative references to [...]
                  an immutable copy of the evaluation structure of <expr>")
          (number 2))
        ($let* ((formals (list qx qy))
                (body    (list list qy qx))
                (comb    (eval (list $vau formals #ignore body)
                              (make-kernel-standard-environment)))
                (env     (make-environment))
                (res1    (eval-protect (list comb 1 2) env))
                (#ignore (set-car! body qx))
                (res2    (eval-protect (list comb 3 4) env)))
          ($check equal? res1 (list event-return (list 2 1)))
          ($check equal? res2 (list event-return (list 4 3))))))))


