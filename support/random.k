;;;
;;; random.k
;;;
;;; A random number generator.
;;;
;;; ($with-random . BODY)
;;;
;;; (random-integer N)
;;;
;;;   Return random integer in the range [0...N-1]. N should not be
;;;   larger than about 50 (TODO: fix that).
;;;
;;; (random-boolean) => BOOLEAN
;;;
;;;   Return #t or #f at random.
;;;
;;; (random-list-element XS)
;;;
;;;   Return randomly chosen element of XS.
;;;

($provide! (make-random-generator)

  ($provide! (make-basic-generator)

    ($define! modular-div
      ($lambda (u v p)
        ($if (=? v 1)
          u
          ($let (((q r) (div-and-mod p v)))
            (modular-div (mod (- p (* q u)) p) r p)))))

    ($define! icg
      ($lambda (p a b y)
        ($define! my (get-current-environment))
        ($lambda ()
          ($set! my y ($if (zero? y)
                          b
                          (mod (+ (* a (modular-div 1 y p)) b) p)))
          y)))

    ($define! make-basic-generator
      ($lambda ()
        ($let ((i1 (icg 1031 849 1 0))
               (i2 (icg 1033 413 1 1))
               (i3 (icg 1039 173 1 2))
               (i4 (icg 2027 579 1 3)))
          (list
            ($lambda () (+ (i1) (i2) (i3) (i4)))
            5000)))))

  ($define! make-random-generator
    ($lambda ()
      ($let (((f m) (make-basic-generator)))
        ($lambda (n)
          ($if (<? (* n n) m)
            (mod (f) n)
            (error "make-random-generator")))))))

($provide! ($with-random
            random-integer random-boolean random-list-element
            $random-choice)

  ($define! (bind-random access-random)
    (make-keyed-dynamic-variable))

  ($define! $with-random
    ($vau body denv
      (bind-random (make-random-generator)
        ($lambda () (eval (cons $sequence body) denv)))))

  ($define! random-integer
    ($lambda args
      (apply (access-random) args)))

  ($define! random-boolean
    ($lambda ()
      (equal? (random-integer 2) 0)))

  ($define! random-list-element
    ($lambda (xs)
      (list-ref xs (random-integer (length xs)))))

  ($define! $random-choice
    ($vau options denv
      (eval (random-list-element options) denv))))

