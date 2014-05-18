;;;
;;; types.k
;;;
;;; Test encapsulation and partitioning of types.
;;;

($test-group types
    ((plan encapsulation-of-types partitioning-of-types))

  ($define! types
    (list (list boolean? #t #f)
          (list null? ())
          (list inert? #inert)
          (list ignore? #ignore)
          (list pair? (list #t) (list #f #t))
          (cons symbol? ((unwrap list) a b c))
          (list environment? (make-environment)
                             (get-current-environment)
                             (make-kernel-standard-environment))
          (list operative? $if ($vau #ignore #ignore #inert))
          (list applicative? list ($lambda #ignore #inert))))
  ($define! n (length types))
  ($define! m (apply + (map length types)))

  ($test-group partitioning-of-types
      ((cite (kernel-report "3.5")
         "The primitive type predicates must partition all possible objects;
         that is, every object must satisfy exactly one primitive type predicate.")
       (number (* n (- m n))))
    ($let ((types (list (list boolean? #t #f)
                        (list null? ())
                        (list inert? #inert)
                        (list ignore? #ignore)
                        (list pair? (list #t) (list #f #t))
                        (cons symbol? ((unwrap list) a b c))
                        (list environment? (make-environment)
                                          (get-current-environment)
                                          (make-kernel-standard-environment))
                        (list operative? $if ($vau #ignore #ignore #inert))
                        (list applicative? list ($lambda #ignore #inert)))))
      (for-each
        ($lambda (((p . xs) (q . #ignore)))
          (for-each
            ($lambda (x)
              ($check eq? (apply q (list x)) (equal? p q)))
            xs))
        (list-product types types)))))
