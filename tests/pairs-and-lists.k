($test-group pairs-and-lists
    ((cite (kernel-report 4 6)
           (kernel-report 5 2)
           (kernel-report 5 7)
           (kernel-report 6 3))
     (plan external-representation
           cons list list*
           get-list-metrics list-tail
           length list-ref append list-neighbors filter assoc
           member? finite-list? countable-list? reduce))

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
          (list 1 #f (list 1 2 3) ($quote x) list))))

;;
;; list*
;;

  ($test-group list*
      ((cite (kernel-report 5 2 2))
       (plan induction kernel-report-examples error-handling))

    ($test-group induction
        ((cite (kernel-report 5 2 2)
               "The following equivalences hold:
                (list* arg1 ) == arg1
                (list* arg1 arg2 . args) == (cons arg1 (list* arg2 . args))")
         (number 7))
      ($check equal? (list* #inert) #inert)
      ($let ((e (make-kernel-standard-environment)))
        (for-each
          ($lambda (args)
            ($check equal? (eval (cons list* (cons #t (cons #f args))) e)
                           (cons #t (eval (cons list* (cons #f args)) e))))
          ($quote (() (1) (1 2) (1 2 3) (1 2 3 4) (1 2 3 4 5))))))

    ($test-group kernel-report-examples
        ((number 4))
      ($eval-table
        ((list* 1)        1)
        ((list* 1 2)      ($quote (1 . 2)))
        ((list* 1 2 3)    ($quote (1 2 . 3)))
        ((list* 1 2 3 ()) ($quote (1 2 3)))))

    ($test-group error-handling
        ((cite (kernel-report 5 2 2)
               "(list* . objects), objects should be a finite nonempty list of arguments")
         (plan empty-list nonlist cyclic-list))
      ($test-group empty-list
          ((number 1))
        ($check-error (list*)))
      ($test-group nonlist
          ((number 3))
        ($check-error (apply list* 1))
        ($check-error (apply list* #t))
        ($check-error (apply list* list*)))
      ($test-group cyclic-list
          ((require-modules pair-mutation)
           (number 2))
        ($check-error (apply list* (cyclic-list 1)))
        ($check-error (apply list* (cons 0 (cyclic-list 1 2 3)))))))

;;
;; get-list-metrics
;;

  ($test-group get-list-metrics
      ((cite (kernel-report 5 7 1)
             "Applicative get-list-metrics constructs and returns a list
              of exact integers of the form (p n a c), where p, n, a, and c
              are, respectively, the number of pairs in, the number of nil
              objects in, the acyclic prefix length of, and the cycle length
              of, the improper list starting with object. n is either 0 or 1,
              a + c = p, and n and c cannot both be non-zero.")
       (plan nonpair finite-list acyclic-improper-list cyclic-list
             error-handling))

    ($test-group nonpair
        ((cite (kernel-report 5 7 1)
               "if a = c = 0, object is not a pair")
         (number 9))
      (for-each
        ($lambda (object)
          ($check equal? (get-list-metrics object) (list 0 0 0 0)))
        (list #t #f #inert #ignore ($quote symbol)
              1 list $if (get-current-environment))))

    ($test-group finite-list
        ((cite (kernel-report 5 7 1)
               "if n = 1, the improper list is a finite list")
         (number 5))
      (for-each
        ($lambda ((p object))
          ($check equal? (get-list-metrics object) (list p 1 p 0)))
        ($quote ((0 ())
                 (1 (x))
                 (2 (#t #f))
                 (3 (() () ()))
                 (4 (1 2 3 4))))))

    ($test-group acyclic-improper-list
        ((cite (kernel-report 5 7 1)
               "if c = 0, the improper list is acyclic")
         (number 4))
      (for-each
        ($lambda ((p object))
          ($check equal? (get-list-metrics object) (list p 0 p 0)))
        ($quote ((1 (x . y))
                 (2 (1 2 . 3))
                 (3 (#t #f () . #ignore))
                 (4 (1 2 3 4 . 5))))))

    ($test-group cyclic-list
        ((cite (kernel-report 5 7 1))
         (number 6))
      ($letrec ((prepend ($lambda (n x)
                           ($if (positive? n)
                             (prepend (- n 1) (cons n x))
                             x))))
        (for-each
          ($lambda ((a c))
            ($check equal? (get-list-metrics (prepend a (apply cyclic-list (prepend c ()))))
                           (list (+ a c) 0 a c)))
          ($quote ((0 1) (0 2) (0 3)
                   (1 1) (1 2) (17 25))))))

    ($test-group error-handling
        ((number 20))
      ($fuzz-applicative 20 get-list-metrics
        ($lambda (x) ($and? (pair? x) (null? (cdr x))))
        ((list 1 2 3))))))
