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
        ((list* 1 2)      ((unwrap list) . (1 . 2)))
        ((list* 1 2 3)    ((unwrap list) . (1 2 . 3)))
        ((list* 1 2 3 ()) ((unwrap list) . (1 2 3)))))

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
         (require-modules pair-mutation)
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
        ((list 1 2 3)))))

;;
;; list-tail
;;

  ($test-group list-tail
      ((cite (kernel-report 5 7 2)
             "The list-tail applicative follows /integer/ cdr references
              starting from /object/.")
       (plan induction long-list cyclic-list error-handling))

    ($test-group induction
        ((cite (kernel-report 5 7 2)
               "The following equivalences hold:
                (list-tail object 0) == object
                (list-tail object (+ k 1)) == (list-tail (cdr object) k)")
         (number 11))
      (for-each
        ($lambda ((object ks))
          ($check equal? (list-tail object 0) object)
          (for-each
            ($lambda (k)
              ($check equal? (list-tail object (+ k 1)) (list-tail (cdr object) k)))
            ks))
        ($quote
          ((()            ())
           (#f            ())
           (0             ())
           ((1 2 3 4 . 5) (0 1 2 3))
           (((1 2) (3 4)) (0 1))))))

    ($test-group long-list
        ((require-standard-bindings append)
         (number 4))
      ($define! a (list 0 1 2 3 4 5 6 7 8 9))
      ($define! b (append a a a a a a a a a))
      ($define! c (append b b b b b b b b b))
      ($define! d (append c c c c c c c c c))
      ($check equal? (list-tail b 90) ())
      ($check equal? (list-tail c 810) ())
      ($check equal? (list-tail d 7290) ())
      ($check equal? (car (list-tail d 6789)) 9))

    ($test-group cyclic-list
        ((cite (kernel-report 5 7 2))
         (require-modules pair-mutation)
         (number 7))
      ($define! object-0 (list* 1 2 (cyclic-list 3 4 5)))
      ($define! object-1 (cons 2 (cyclic-list 3 4 5)))
      ($define! object-2 (cyclic-list 3 4 5))
      ($define! object-3 (cyclic-list 4 5 3))
      ($define! object-4 (cyclic-list 5 3 4))
      ($check equal? (list-tail object-0 0) object-0)
      ($check equal? (list-tail object-0 1) object-1)
      ($check equal? (list-tail object-0 2) object-2)
      ($check equal? (list-tail object-0 3) object-3)
      ($check equal? (list-tail object-0 4) object-4)
      ($check equal? (list-tail object-0 5) object-2)
      ($check equal? (list-tail object-0 1234) object-4))

    ($test-group error-handling
        ((plan invalid-integer invalid-object))

      ($test-group invalid-integer
          ((cite (kernel-report 5 7 2)
               "/integer/ should be exact and non-negative")
           (number 4))
        ($define! object (list 1 2 3))
        ($check-error (list-tail #f object))
        ($check-error (list-tail -1 object))
        ($check-error (list-tail (/ 1 2) object))
        ($check-error (list-tail (make-inexact 1 2 3) object)))

      ($test-group invalid-object
          ((cite (kernel-report 5 7 2)
               "/object/ must be the start of an improper list
                containing at least /integer/ pairs")
           (number 4))
        ($check-error (list-tail 1 ()))
        ($check-error (list-tail 2 3))
        ($check-error (list-tail 4 #f))
        ($check-error (list-tail 4 (list 1 2 3))))))

;;
;; length
;;

  ($test-group length
      ((cite (kernel-report 6 3 1)
             "returns the number of consecutive cdr references
              that can be followed starting from /object/")
       (plan finite-list improper-list non-list cyclic-list))

     ($test-group finite-list
         ((number 2))
       ($check equal? (length (cons () ())) 1)
       ($check equal? (length (list #t #t #f #f #t #t #f #f)) 8))

     ($test-group improper-list
         ((number 2))
       ($check equal? (length (cons 1 2)) 1)
       ($check equal? (length (cons 1 (cons 2 3))) 2))

     ($test-group non-list
         ((cite (kernel-report 6 3 1)
                "if /object/ is not a pair, it returns zero")
          (number 3))
       ($check equal? (length ()) 0)
       ($check equal? (length 42) 0)
       ($check equal? (length (get-current-environment)) 0))

    ($test-group cyclic-list
        ((require-modules pair-mutation)
         (require-standard-bindings finite? positive?)
         (plan infinity exactness))

      ($define! objects
        ($let ((a (cyclic-list #t))
               (b (cyclic-list #f #t)))
          (list a b (cons a b) (cons b a))))

      ($test-group infinity
          ((cite (kernel-report 6 3 1)
                 "if object is a cyclic list, it returns positive infinity")
           (number 8))
        (for-each
          ($lambda (object)
            ($check equal? (positive? (length object)) #t)
            ($check equal? (finite? (length object)) #f))
          objects))

      ($test-group exactness
          ((cite (kernel-report 6 3 1)
                 "length returns the (exact) [...] length")
           (require-modules inexact)
           (number 4))
        (for-each
          ($lambda (object)
            ($check equal? (exact? (length object)) #t))
          objects))))

;;
;; list-ref
;;

  ($test-group list-ref
      ((cite (kernel-report 6 3 2)
             "returns the /integer/-th element of list, zero-indexed")
       (plan normal-operation error-handling))

    ($test-group normal-operation
        ((number 2))
      ($eval-table
        ((list-ref (list 1 2) 0) 1)
        ((list-ref ((unwrap list) a b c d e f) 5) ((unwrap list) . f))))

    ($test-group error-handling
        ((number 3))
      ($check-error (list-ref () 1))
      ($check-error (list-ref (list 1 2) 3))
      ($check-error (list-ref (list 1 2) #t))))

;;
;; append
;;

  ($test-group append
      ((cite (kernel-report 6 3 3))
       (plan freshly-allocate reference-last equivalences cyclic-argument-list error-handling))

    ($test-group freshly-allocate
        ((cite (kernel-report 6 3 3)
               "returns a freshly allocated list of the elements of all
                the specified lists, in order, except...")
         (require-modules pair-mutation)
         (number 2))
      ($define! tail (list 1 2 3))
      ($define! result (append tail tail ()))
      ($check equal? result (list 1 2 3 1 2 3))
      (set-car! tail #t)
      ($check equal? result (list 1 2 3 1 2 3)))

    ($test-group reference-last
        ((cite (kernel-report 6 3 3)
               "if there is a last specified element of /lists/, it
                is not copied, but is simply referenced by the cdr
                of the preceding pair (if any) in the resultant list")
         (require-modules pair-mutation)
         (number 5))
      ($define! tail (list 1 2 3))
      ($check eq? (append tail) tail)
      ($define! res1 (append tail tail))
      ($define! res2 (append tail tail tail))
      ($check equal? res1 (list 1 2 3 1 2 3))
      ($check equal? res2 (list 1 2 3 1 2 3 1 2 3))
      (set-car! tail #t)
      ($check equal? res1 (list 1 2 3 #t 2 3))
      ($check equal? res2 (list 1 2 3 1 2 3 #t 2 3)))

    ($test-group equivalences
        ((cite (kernel-report 6 3 3)
               "The following equivalences hold.
                  (append) == ()
                  (append h) == h
                  (append () h . t) == (append h . t)
                  (append (cons a b) h . t) == (cons a (append b h . t))")
         (number 94))
      ($let ((objects (list () #t (cons -1 -2)))
             (lists (list () (list () #t) (list 1 2 3)))
             (lists-of-lists (list () (list ()) (list (list 1 2) (list 3 5 #f)))))
        ($check equal? (append) ())
        (for-each
          ($lambda (h) ($check equal? (append h) h))
          objects)
        (for-each
          ($lambda ((h t))
            ($check equal? (apply append (list* () h t))
                           (apply append (cons h t))))
          (list-product lists lists-of-lists))
        (for-each
          ($lambda (((a b) (h t)))
            ($check equal? (apply append (list* (cons a b) h t))
                           (cons a (apply append (list* b h t)))))
          (list-product (list-product objects lists)
                        (list-product lists lists-of-lists)))))

    ($test-group cyclic-argument-list
        ((cite (kernel-report 6 3 3)
               "If lists is cyclic, the cycle of the result list
                consists of just the elements of the lists specified
                in the cycle in lists.")
         (require-modules pair-mutation)
         (number 1))
       ($define! cs
         (list* (list 1 2 3)
                (list 4 5)
                (cyclic-list (list 6 7 8)
                             (list 9 10))))
       ($check equal? (apply append cs)
                      (list* 1 2 3 4 5 (cyclic-list 6 7 8 9 10))))

    ($test-group error-handling
        ((cite (kernel-report 6 3 3)
               "all the elements of /lists/ except the last element
                (if any) must be acyclic lists")
         (plan non-list cyclic-list))
      ($test-group non-list
          ((number 3))
        ($check-error (append 1 ()))
        ($check-error (append 1 2))
        ($check-error (append (list 1 2) $if (list 3 4))))
      ($test-group cyclic-list
          ((require-modules pair-mutation)
           (number 3))
        ($check-error (append (cyclic-list 1) ()))
        ($check-error (append (list 1 2) (cyclic-list 2 3) 5))
        ($check-error (append (cyclic-list #t) (cyclic-list #f))))))

;;
;; list-neighbors
;;

  ($test-group list-neighbors
      ((cite (kernel-report 6 3 4))
       (plan nil acyclic-examples cyclic-examples
             acyclic-length cyclic-structure
             non-list))

    ($test-group nil
        ((cite (kernel-report 6 3 4)
               "if /list/ is nil, the result is nil")
         (number 1))
       ($check equal? (list-neighbors ()) ()))

    ($test-group acyclic-examples
        ((number 4))
      (for-each
        ($lambda ((a b))
          ($check equal? (list-neighbors a) b))
        ((unwrap list)
          ((1)       ())
          ((1 2)     ((1 2)))
          ((1 2 3)   ((1 2) (2 3)))
          ((1 2 3 4) ((1 2) (2 3) (3 4))))))

    ($test-group acyclic-length
        ((cite (kernel-report 6 3 4)
               "If /list/ is non-nil, the length of the result is one
                less than the length of /list/")
         (number 3))
       ($let* ((x (list 0 1 2 3 4 5 6 7 8 9))
               (y (append x x))
               (z (append y y)))
         (for-each
           ($lambda (x)
             ($check equal? (length (list-neighbors x))
                            (- (length x) 1)))
           (list x y z))))

    ($test-group cyclic-examples
        ((require-modules pair-mutation)
         (number 3))
      ($check equal?
        (list-neighbors (cyclic-list #t))
        (cyclic-list (list #t #t)))
      ($check equal?
        (list-neighbors (cyclic-list 1 2 3))
        (cyclic-list (list 1 2) (list 2 3) (list 3 1)))
      ($check equal?
        (list-neighbors (list* 1 2 (cyclic-list 3 4)))
        (list* (list 1 2) (list 2 3) (cyclic-list (list 3 4) (list 4 3)))))

    ($test-group cyclic-structure
        ((cite (kernel-report 6 3 4)
               "If /list/ is cyclic, the result is structurally isomorphic
                to it (i.e., has the same acyclic prefix length and cycle length).")
         (require-modules pair-mutation)
         (number 3))
       ($let* ((a (cyclic-list 0 1 2 3 4 5 6 7 8 9))
               (b (cyclic-list 10 11 12))
               (p (list 0 1 2 3 4 5 6 7 8 9))
               (c (append p p a)))
         (for-each
           ($lambda (x)
             ($check equal?
               (cddr (get-list-metrics (list-neighbors x)))
               (cddr (get-list-metrics x))))
           (list a b c))))

    ($test-group non-list
        ;;; XXX The derivation in the Kernel Report never raises
        ;;;     and error. However, klisp does raise an error
        ;;;     if the argument is not proper list.
        ((number 3))
      ($check-error (list-neighbors 1))
      ($check-error (list-neighbors (cons 1 2)))
      ($check-error (list-neighbors (list* 1 2 3)))))

;;
;; filter
;;

  ($test-group filter
      ((cite (kernel-report 6 3 5))
       (plan pass-elements empty-environment same-order cyclic-structure
             continuation-safety error-handling))

    ($test-group pass-elements
        ((cite (kernel-report 6 3 5)
               "Applicative filter passes each of the elements of /list/ as an
                argument to /applicative/")
         (number 9))
      ($define! log ())
      ($define! input (list 1 #t 3 #f))
      ($let ((env (get-current-environment)))
        ($check equal?
          (filter ($lambda (x) ($set! env log (cons x log)) #f) input)
          ()))
      (for-each ($lambda (x) ($check (member? x log))) input)
      (for-each ($lambda (x) ($check (member? x input))) log))

    ($test-group empty-environment
        ((cite (kernel-report 6 3 5)
               "using a fresh empty environment for each call")
         (number 5))
      ($check equal?
        (filter
          (wrap ($vau (x) e
            ($check (not? ($binds? e filter)))
            ($set! e filter "some-value")
            (integer? x)))
          (list 1 #t 3 #f))
        (list 1 3)))

    ($test-group same-order
        ((cite (kernel-report 6 3 5)
               "filter constructs and returns a list of all elements of /list/ on
                which /applicative/ returned true, in the same order as in /list/")
         (number 4))
      ($check equal? (filter integer? (list 2 "x" -3 ($quote t) 10 #inert)) (list 2 -3 10))
      ($check equal? (filter ignore?  (list #ignore #inert #ignore))        (list #ignore #ignore))
      ($check equal? (filter boolean? (list 1 #t 3 #f 6 #t 9 #t -2 #f))     (list #t #f #t #t #f))
      ($check equal? (filter not?     (list #t #f #f #t #f #t #t #f))       (list #f #f #f #f)))

    ($test-group cyclic-structure
        ((cite (kernel-report 6 3 5)
               "The resultant list has a cycle containing exactly those elements
                accepted by applicative that were in the cycle of list; if there
                were no such elements, the result is acyclic.")
         (require-modules pair-mutation)
         (number 5))
      ($define! x (list* 1 2 3 4 (cyclic-list 5 6 7 8)))
      ($check equal? (filter even? x)                    (list* 2 4 (cyclic-list 6 8)))
      ($check equal? (filter odd? x)                     (list* 1 3 (cyclic-list 5 7)))
      ($check equal? (filter pair? x)                    ())
      ($check equal? (filter ($lambda (x) (<? 5 x 7)) x) (cyclic-list 6))
      ($check equal? (filter ($lambda (x) (<? x 4)) x)   (list 1 2 3)))

    ($test-group continuation-safety
        ((number 2))
      ($check equal?
        ($let/cc k
          (filter
            ($lambda (x) ($if (integer? x) (apply-continuation k x) (boolean? x)))
            (list #t 42 #f)))
        42)
      ($letrec ((acc ())
                (env (get-current-environment)))
        ($set! env acc
          (cons (filter
                  ($lambda (x)
                    ($if (integer? x)
                      ($let/cc k ($set! env k k) #t)
                      #t))
                  (list #t 0 #f))
                acc))
        ($if (=? (length acc) 3)
          ($check equal?
            acc
            (list (list #t 0 #f) (list #t #f) (list #t 0 #f)))
          (apply-continuation k (even? (length acc))))))

    ($test-group error-handling
        ((plan not-applicative not-list not-boolean))
      ($test-group not-applicative
          ((number 3))
        ($check-error (filter 1 ()))
        ($check-error (filter (unwrap integer?) (list 1 2 3)))
        ($check-error (filter (list 1 2 3) integer?)))
      ($test-group not-list
          ((number 3))
        ($check-error (filter integer? 1))
        ($check-error (filter pair? pair?))
        ($check-error (filter (list 1 2 3) integer?)))
      ($test-group not-boolean
          ((number 3))
        ($check-error (filter list (list 1 2 3)))
        ($check-error (filter list* (list 1 2 3)))
        ($check-error (filter ($lambda (x) ()) (list #t #f))))))

;;
;; assoc
;;

  ($test-group assoc
      ((cite (kernel-report 6 3 6)
             "Applicative /assoc/ returns the first element
               of /pairs/ whose car is equal? to /object/.")
       (plan single multiple none cyclic error-handling))

    ($test-group single
         ((number 5))
       ($define! pairs
         ((unwrap list)
           (1 5)
           (#t #f)
           ((2 3) (4 3))
           ((2 4) (6 7))
           (#f)))
       (for-each
         ($lambda ((k e)) ($check equal? (assoc k pairs) e))
         ((unwrap list)
           (1     (1 5))
           (#t    (#t #f))
           ((2 3) ((2 3) (4 3)))
           ((2 4) ((2 4) (6 7)))
           (#f    (#f)))))

    ($test-group multiple
        ((number 3))
      ($define! pairs
        ((unwrap list) (1 5) (2 ()) (1 6) (2 4) (3 7) (3 8)))
      (for-each
        ($lambda ((k e)) ($check equal? (assoc k pairs) e))
        ((unwrap list) (1 (1 5)) (2 (2 ())) (3 (3 7)))))

    ($test-group none
        ((cite (kernel-report 6 3 6)
             "If there is no such element in /pairs/, nil is returned.")
          (number 3))
      ($define! pairs
        ((unwrap list) (#t #f) (2 3) ((1 2))))
      (for-each
        ($lambda ((k e)) ($check equal? (assoc k pairs) e))
        ((unwrap list) (1 ()) (#f ()) ((1 3) ()))))

    ($test-group cyclic
        ((require-modules pair-mutation)
         (number 3))
      ($define! pairs
        (cons (list 1 2)
              (cyclic-list (cons 2 3) (list () ()))))
      (for-each
        ($lambda ((k e)) ($check equal? (assoc k pairs) e))
        ((unwrap list) (1 (1 2)) (2 (2 . 3)) (() (() ())))))

    ($test-group error-handling
        ((number 5))
      ($check-error (assoc (list 1 2) 1))
      ($check-error (assoc (cons 1 2) (cons 3 4)))
      ($check-error (assoc 0 (list* 1 2 3 4 5 6)))
      ($check-error (assoc #t #f))
      ($check-error (assoc assoc assoc))))

;;
;; member?
;;

  ($test-group member?
      ((cite (kernel-report 6 3 7)
             "Applicative member? is a predicate that returns true iff some
              element of /list/ is equal? to /object/.")
       (plan acyclic cyclic error-handling))

    ($test-group acyclic
         ((number 9))
       ($define! pairs
         ((unwrap list) 1 #t (x y) ((2 3) (4 3)) (#f)))
       (for-each
         ($lambda ((k e)) ($check equal? (member? k pairs) e))
         ((unwrap list)
           (0    #f)  (1     #t)  (x             #f)
           (#f   #f)  (#t    #t)  (()            #f)
           ((#f) #t)  ((x y) #t)  (((2 3) (4 4)) #f))))

    ($test-group cyclic
        ((require-modules pair-mutation)
         (number 6))
      ($define! pairs
        (list* #t () (cyclic-list 1 -1)))
      (for-each
        ($lambda ((k e)) ($check equal? (member? k pairs) e))
        ((unwrap list)
          (#t  #t)  (#f  #f)  (()  #t)
          (1   #t)  (0   #f)  (-1  #t))))

    ($test-group error-handling
        ((number 5))
      ($check-error (member? (list 1 2) 1))
      ($check-error (member? (cons 1 2) (cons 3 4)))
      ($check-error (member? 0 (list* 1 2 3 4 5 6)))
      ($check-error (member? #t #f))
      ($check-error (member? assoc assoc))))

;;
;; finite-list?
;;

  ($test-group finite-list?
      ((cite (kernel-report 6 3 8)
             "returns true iff all its arguments are acyclic lists")
       (plan acyclic cyclic error-handling))

    ($test-group acyclic
        ((number 15))
      ($eval-table
        ((finite-list? ())                        #t)
        ((finite-list? (cons #t ()))              #t)
        ((finite-list? (list 1 2 3))              #t)
        ((finite-list? (list 1 2 3 4 5 6))        #t)
        ((finite-list? #inert)                    #f)
        ((finite-list? "xyz")                     #f)
        ((finite-list? #f)                        #f)
        ((finite-list? (get-current-environment)) #f)
        ((finite-list? ((unwrap list) . nil))     #f)
        ((finite-list? (cons 1 2))                #f)
        ((finite-list? (list* 1 2 3 4))           #f)
        ((finite-list?)                           #t)
        ((finite-list? (list 1 2) (list 3 4))     #t)
        ((finite-list? () () () () () () ())      #t)
        ((finite-list? (list 1) 2 (list 3) 4)     #f)))

    ($test-group cyclic
        ((require-modules pair-mutation)
         (number 4))
      ($check equal? (finite-list? (cyclic-list 1)) #f)
      ($check equal? (finite-list? (cyclic-list 2 3 4) 2) #f)
      ($check equal? (finite-list? (list* 1 2 (cyclic-list 2 3))) #f)
      ($check equal? (finite-list? (list 1 1 1 1 1) (cyclic-list 1 1)) #f))

    ($test-group error-handling
        ((number 2))
      ($check-error (finite-list? . #inert))
      ($check-error (finite-list? () . 1))))

;;
;; countable-list?
;;

  ($test-group countable-list?
      ((cite (kernel-report 6 3 8)
             "returns true iff all its arguments are lists")
       (plan acyclic cyclic error-handling))

    ($test-group acyclic
        ((number 15))
      ($eval-table
        ((countable-list? ())                        #t)
        ((countable-list? (cons #t ()))              #t)
        ((countable-list? (list 1 2 3))              #t)
        ((countable-list? (list 1 2 3 4 5 6))        #t)
        ((countable-list? #inert)                    #f)
        ((countable-list? "xyz")                     #f)
        ((countable-list? #f)                        #f)
        ((countable-list? (get-current-environment)) #f)
        ((countable-list? ((unwrap list) . nil))     #f)
        ((countable-list? (cons 1 2))                #f)
        ((countable-list? (list* 1 2 3 4))           #f)
        ((countable-list?)                           #t)
        ((countable-list? (list 1 2) (list 3 4))     #t)
        ((countable-list? () () () () () () ())      #t)
        ((countable-list? (list 1) 2 (list 3) 4)     #f)))

    ($test-group cyclic
        ((require-modules pair-mutation)
         (number 4))
      ($check equal? (countable-list? (cyclic-list 1)) #t)
      ($check equal? (countable-list? (cyclic-list 2 3 4) 2) #f)
      ($check equal? (countable-list? (list* 1 2 (cyclic-list 2 3))) #t)
      ($check equal? (countable-list? (list 1 1 1 1 1) (cyclic-list 1 1)) #t))

    ($test-group error-handling
        ((number 2))
      ($check-error (countable-list? . #inert))
      ($check-error (countable-list? () . 1))))

;;
;; reduce
;;

  ($test-group reduce
      ((cite (kernel-report 6 3 10))
       (plan empty acyclic cyclic calls dynamic-environment error-handling))

    ($test-group empty
        ((cite (kernel-report 6 3 10)
               "If /list/ is empty, applicative reduce returns identity.")
         (number 3))
      ($eval-table
        ((reduce () + 0)        0)
        ((reduce () cons ())    ())
        ((reduce () error list) list)))

    ($test-group acyclic
        ((cite (kernel-report 6 3 10)
               "If /list/ is nonempty but acyclic, applicative reduce uses binary
                operation /binary/ to merge all the elements of list into a single
                object, using any associative grouping of the elements.")
         (number 6))
      ($eval-table
        ((reduce (list 1 2 3 4 5 6 7 8) + 9)  36)
        ((reduce (list -4 -3 -2 -1 2 3) * 9) 144)
        ((reduce (list 10 20 -30 -10) max 0)  20)
        ((reduce (list #t #t #f #t) and? #t)  #f)
        ((reduce (list 1 2 3 4) boolean? #t)  #f)
        ((reduce (list 1 2) environment? #f)  #f)))

    ($test-group cyclic
        ((cite (kernel-report 6 3 10)
               "The elements of the cycle are passed, one at a time [...] as arguments
                to unary applicative /precycle/; the finite, cyclic sequence of results
                from precycle is reduced using binary applicative /incycle/; and the result
                from reducing the cycle is passed as an argument to unary applicative
                postcycle. Binary operation /binary/ is used to reduce the sequence
                consisting of the elements of the acyclic prefix of list followed by the
                result returned by postcycle.")
         (require-modules pair-mutation)
         (number 4))
      ($define! cycle (cyclic-list 4 -5 6))
      ($check equal? (reduce cycle append () list append car) 4)
      ($check equal? (reduce cycle max 2 abs + list) (list 15))
      ($check equal? (reduce cycle min 3 min min min) -5)
      ($check equal? (reduce (list* 1 -2 3 cycle) + 0 abs + abs) 17))

    ($test-group calls
        ((plan cyclic acyclic))
      ($define! state (make-environment))
      ($define! names ((unwrap list) binary precycle incycle postcycle))
      ($define! ops   (list          +      list*    +       list*))
      (for-each
        ($let ((env (get-current-environment)))
          ($lambda (name op)
            (set! env name
              ($lambda args
                (set! state name (+ 1 (eval name state)))
                (apply op args)))))
        names ops)
      ($test-group acyclic
          ((cite (kernel-report 6 3 10)
                 "If /list/ is acyclic with length n >= 1, binary is called n - 1 times.")
           (number 1))
        (set! state names (list 0 0 0 0))
        (reduce (list 1 2 3 4 5) binary 0 precycle incycle postcycle)
        ($check equal? (apply (wrap list) names state) (list 4 0 0 0)))
      ($test-group cyclic
          ((cite (kernel-report 6 3 10)
                 "If /list/ is cyclic with acyclic prefix length /a/ and cycle length /c/,
                  binary is called /a/ times; precycle, /c/ times; incycle, /c/ - 1 times;
                  and postcycle, once.")
           (require-modules pair-mutation)
           (number 1))
        (set! state names (list 0 0 0 0))
        (reduce (list* 1 2 (cyclic-list 3 4 5 6)) binary 0 precycle incycle postcycle)
        ($check equal? (apply (wrap list) names state) (list 2 4 3 1))))

    ($test-group dynamic-environment
        ((cite (kernel-report 6 3 10)
               "Each call to binary, precycle, incycle, or postcycle uses
                the dynamic environment of the call to reduce.")
         (plan cyclic acyclic))
      ($define! state     (make-environment))
      ($define! check-env ($lambda (e) ($check equal? e ($remote-eval env state))))
      ($define! binary    (wrap ($vau (x y) e (check-env e) (+ x y))))
      ($define! precycle  (wrap ($vau (x) e (check-env e) (* 10 x))))
      ($define! incycle   binary)
      ($define! postcycle precycle)
      ($test-group acyclic
          ((number 3))
        ($define! e1 (get-current-environment))
        ($set! state env e1)
        ($check equal? 6
                       (reduce (list 1 2 3) binary 0 precycle incycle postcycle)))
      ($test-group cyclic
          ((require-modules pair-mutation)
           (number 7))
        ($define! e2 (get-current-environment))
        ($check (not? (equal? e2 ($remote-eval env state))))
        ($set! state env e2)
        ($check equal? 501
                       (reduce (cons 1 (cyclic-list 2 3)) binary 0 precycle incycle postcycle))))

    ($test-group error-handling
        ((plan list applicatives cyclic))
      ($test-group list 
          ((cite (kernel-report 6 3 10)
                 "/list/ should be a list")
           (number 2))
        ($check-error (reduce 5 max 0 max max max))
        ($check-error (reduce max max max max max max)))
      ($test-group applicatives
          ((cite (kernel-report 6 3 10)
                 "/binary/ should be an applicative [...] if the second call syntax
                 is used, precycle, incycle, and postcycle should be applicatives.")
           (number 2))
        ($check-error (reduce (list 1 2) (unwrap list) 0))
        ($check-error (reduce (list 1 2) list 0 (unwrap list) (unwrap list) (unwrap list))))
      ($test-group cyclic
          ((cite (kernel-report 6 3 10)
                 "If the first call syntax is used, /list/ should be an acyclic
                  list [...] If /list/ is cyclic, the second call syntax must be used.")
           (require-modules pair-mutation)
           (number 2))
        ($check-error (reduce (cyclic-list 1) + 0))
        ($check-error (reduce (cons 1 (cyclic-list 2 3)) + 0)))))

)
