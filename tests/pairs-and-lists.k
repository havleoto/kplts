($test-group pairs-and-lists
    ((cite (kernel-report 4 6))
     (plan external-representation
           cons list list*))

  ($test-group external-representation
      ((cite (kernel-report 4 6))
       (number 3))
    ; "The null data type consists of a single immutable value, called nil or
    ;  the empty list and having external representation (), with or without
    ;  whitespace between the parentheses."
    ($check (null? () ( ) (
) (;comment
)))
    ($check equal? ($quote (1 . 2)) (cons 1 2))
    ($check
      equal?
      ($quote (1 . (2 . (3 . ()))))
      ($quote (1 2 3))))

  ($test-group cons
      ((cite (kernel-report 4 6 3))
       (plan normal-operation error-handling))
    ($test-group normal-operation
        ((number 3))
      ($check equal? (car (cons "a" "d")) "a")
      ($check equal? (cdr (cons "a" "d")) "d")
      ; equality of pairs
      ($check equal? (cons (cons "aa" "ad") "d") (cons (cons "aa" "ad") "d")))
    ($test-group error-handling
        ((number 3))
      ; arity
      ($check-error (cons))
      ($check-error (cons 1))
      ($check-error (cons 1 2 3))))

;;
;; list
;;

  ($test-group list
      ((cite (kernel-report 5 2 1))
       (plan simple-cases
             operative-operand-tree
             apply-list-equivalence))

    ($test-group simple-cases
        ((number 7))
      ($check equal? (list)
                     ())
      ($check equal? (list ())
                     (cons () ()))
      ($check equal? (list #ignore #inert)
                     (cons #ignore (cons #inert ())))
      ($check equal? (list #t #f #t)
                     (cons #t (cons #f (cons #t ()))))
      ($check equal? (list 1 2 3 4)
                     (cons 1 (cons 2 (cons 3 (cons 4 ())))))
      ($check equal? (list 1 2 3 4 5)
                     (cons 1 (cons 2 (cons 3 (cons 4 (cons 5 ()))))))
      ($check equal? (list 1 2 3 4 5 6)
                     (cons 1 (cons 2 (cons 3 (cons 4 (cons 5 (cons 6 ()))))))))

    ($test-group operative-operand-tree
        ((cite (kernel-report 5 2 1)
               "The underlying operative of list returns its undifferentiated
                operand tree, regardless of whether that tree is or is not
                a list.")
         (plan finite-list improper-list cyclic-list nonlist))
      ($let (($list (unwrap list)))
        ($test-group finite-list
            ((number 5))
          ($check equal? ($list) ())
          ($check equal? ($list #inert) ($quote (#inert)))
          ($check equal? ($list #t #f) ($quote (#t #f)))
          ($check equal? ($list 1 2 3) ($quote (1 2 3)))
          ($check equal? ($list 1 2 3 4) ($quote (1 2 3 4))))
        ($test-group improper-list
            ((number 3))
          ($check equal? ($list 1 . 2) ($quote (1 . 2)))
          ($check equal? ($list 1 2 . 3) ($quote (1 2 . 3)))
          ($check equal? ($list 1 2 3 . 4) ($quote (1 2 3 . 4))))
        ($test-group cyclic-list
            ((require-modules pair-mutation)
             (number 2))
          ($let ((c1 (cyclic-list 1))
                 (c2 (cyclic-list () (cyclic-list #t #f))))
            ($check equal? (eval (cons $list c1)
                                 (make-kernel-standard-environment))
                           c1)
            ($check equal? (eval (cons $list c2)
                                 (make-kernel-standard-environment))
                           c2)))
        ($test-group nonlist
            ((number 3))
          ($check equal? ($list . x) ($quote x))
          ($check equal? ($list . #f) #f)
          ($check equal? (eval (cons $list $list) (make-kernel-standard-environment))
                         $list))))

    ($test-group apply-list-equivalence
        ((cite (kernel-report 5 2 1) "(apply list x) == x")
         (number 5))
        (for-each
          ($lambda (x) ($check equal? (apply list x) x))
          (list 1 #f (list 1 2 3) ($quote x) list)))))
