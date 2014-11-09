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

;;
;; immutability of combiners
;;

  ($let (((qx qy qz) ((unwrap list) x y z)))
    ($test-group immutability
        ((cite (kernel-report 4 10)
              "All combiners are immutable.")
        (require-modules pair-mutation)
        (plan mutate-vau-ptree mutate-vau-formals mutate-vau-body))
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
          ($check equal? res2 (list event-return (list 4 3)))))))

;;
;; equality of combiners
;;

  ($test-group equality
      ((cite (kernel-report 4 10)
             "Two applicatives are eq? iff their underlying combiners are eq?")
       (plan eq? equal? eq?-vs-equal?))

    ($test-group eq?
        ((require-standard-bindings eq?)   ; eq? is optional
         (number 5))
      ($check eq? (wrap $if) (wrap $if))
      ($check eq? (wrap (wrap $if)) (wrap (wrap $if)))
      ($check eq? list (wrap (unwrap list)))
      ($check eq? car (unwrap (unwrap (wrap (wrap car)))))
      ($check eq? $let (unwrap (wrap $let))))

    ($test-group equal?
        ((number 5))
      ($check equal? (wrap $if) (wrap $if))
      ($check equal? (wrap (wrap $if)) (wrap (wrap $if)))
      ($check equal? list (wrap (unwrap list)))
      ($check equal? car (wrap (unwrap (wrap (unwrap car)))))
      ($check equal? $let (unwrap (wrap $let))))

    ($test-group eq?-vs-equal?
        ((cite (kernel-report 4 10)
               "Two combiners are equal? iff they are eq?")
         (require-standard-bindings eq?)
         (number 144))
      (for-each
        ($lambda ((x y))
          ($check equal? (equal? x y) (eq? x y)))
        ($let ((cs (list $if car + $define! eq?
                         (wrap $if) (wrap car) (wrap +)
                         (unwrap continuation?) (unwrap map)
                         (wrap (unwrap car)) (unwrap (wrap $if)))))
          (list-product cs cs)))))

;;
;; wrap
;;

  ($test-group wrap
      ((cite (kernel-report 4 10 4))
       (plan return-applicative underlying-combiner error-handling))
    ($test-group return-applicative
        ((number 5))
      ($check (applicative? (wrap $if)))
      ($check (applicative? (wrap car)))
      ($check (applicative? (wrap ($lambda x (+ x 1)))))
      ($check (applicative? (wrap ($vau x e (eval x e)))))
      ($check (applicative? (wrap (wrap (wrap applicative?))))))
    ($test-group underlying-combiner
        ((number 2))
      ($check equal? (unwrap (wrap $if)) $if)
      ($let ((f ($vau x y 1)))
        ($check equal? (unwrap (wrap f)) f)))
    ($test-group error-handling
        ((number 5))
      ($check-error (wrap 0))
      ($check-error (wrap ((unwrap list) . $if)))
      ($check-error (wrap ((unwrap list) $lambda () ())))
      ($check-error (wrap (get-current-environment)))
      ($check-error (wrap root-continuation))))

;;
;; unwrap
;;

  ($test-group unwrap
      ((cite (kernel-report 4 10 5))
       (plan underlying-combiner-type error-handling))
    ($test-group underlying-combiner-type
        ((number 3))
      ($check (operative? (unwrap car)))
      ($check (operative? (unwrap list)))
      ($check (operative? (unwrap ($lambda x (+ x 1))))))
    ($test-group error-handling
        ((cite (kernel-report 4 10 5)
               "If applicative is not an applicative, an error is signaled.")
         (number 8))
      ($check-error (unwrap $if))
      ($check-error (unwrap $let))
      ($check-error (unwrap $vau))
      ($check-error (unwrap 0))
      ($check-error (unwrap ((unwrap list) . car)))
      ($check-error (unwrap ((unwrap list) $lambda () ())))
      ($check-error (unwrap (get-current-environment)))
      ($check-error (unwrap root-continuation)))))
