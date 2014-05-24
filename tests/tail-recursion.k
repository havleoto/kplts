;;;
;;; tail-recursion.k
;;;
;;; Test unbounded tail recursion.
;;;

($test-group tail-recursion
    ((cite (kernel-report 3 10)
           "A Kernel implementation is properly tail-recursive iff it
            supports an unbounded number of active tail calls.")
     (plan direct-recursion indirect-recursion continuation-capture))

  ($test-group direct-recursion
      ((number 1))
    ($letrec ((f ($lambda (n m)
                   ($if (equal? n 0)
                     m
                     (f (- n 1) (+ m 1)))))
              (k (* 10 appropriate-number-of-calls)))
      ($check equal? (f k 0) k)))

  ($test-group indirect-recursion
      ((number 1))
    ($letrec ((a ($lambda (x y n)
                   (($if (equal? x y) b c) x y n)))
              (b ($lambda (x y n)
                   (d x (not? y) n)))
              (c ($lambda (x y n)
                   (d (not? x) y n)))
              (d ($lambda (x y n)
                   ($if (equal? n 0)
                     (list x y)
                     (a x y (- n 1)))))
              (k (* 4 appropriate-number-of-calls)))
      ($check equal? (a #t #t k) (list #t #f)))))
