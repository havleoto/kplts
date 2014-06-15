($test-group pairs-and-lists
    ((cite (kernel-report 4 6))
     (plan external-representation
           cons))

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
      ($check-error (cons 1 2 3)))))


