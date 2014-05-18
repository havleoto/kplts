;;;
;;; utils.k
;;;
;;; Various utility combiners.
;;;

($define! $increment!
  ($vau (e s) denv
    ($let ((e (eval e denv)))
      (set! e s (+ (eval s e) 1)))))

($define! list-product
  ($lambda (xs ys)
    (apply append
           (map ($lambda (y) (map ($lambda (x) (list x y)) xs)) ys))))
