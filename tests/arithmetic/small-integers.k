;;;
;;; arithmetic/small-integers.k
;;;
;;; Test arithmetic operations with small (less than 1000) integer arguments.
;;;

($test-group +
    ((cite (kernel-report 12 5 4)
           "Applicative + returns the sum of the elements of /numbers/.")
     (require-standard-bindings +)
     (plan empty-argument-list single-argument-list small-random-inputs
           finite-argument-list cycle-of-zeros))

  ($test-group empty-argument-list
      ((cite (kernel-report 12 5 4)
             "If /numbers/ is empty, the sum of its elements is exact zero.")
       (number 1))
    ($check equal? (+) 0))

  ($test-group single-argument-list
      ((number 3))
    ($eval-table
      ((+  0)  0)
      ((+  1)  1)
      ((+ -1) -1)))

  ($test-group small-random-inputs
      ((number 30))
    ($eval-table
      ((+ -64 -39) -103)  ((+ -63 -56) -119)  ((+ -63 -49) -112)
      ((+ -62 -47) -109)  ((+ -61 -63) -124)  ((+ -61   0)  -61)
      ((+ -60   7)  -53)  ((+ -59   1)  -58)  ((+ -53   5)  -48)
      ((+ -49 -62) -111)  ((+ -48 -33)  -81)  ((+ -48   3)  -45)
      ((+ -33   3)  -30)  ((+ -32 -36)  -68)  ((+   0  60)   60)
      ((+   1   0)    1)  ((+   1   1)    2)  ((+   2 -51)  -49)
      ((+   3   5)    8)  ((+   4  -5)   -1)  ((+   5   3)    8)
      ((+   8 -62)  -54)  ((+  15 -63)  -48)  ((+  17 -60)  -43)
      ((+  28  45)   73)  ((+  30 -63)  -33)  ((+  52 -10)   42)
      ((+  54   2)   56)  ((+  59 -59)    0)  ((+  62  12)   74)))

  ($test-group finite-argument-list
      ((number 3))
    ($eval-table
      ((+ 1 6 4)                                  11)
      ((+ 4 5 6 0 1 6 2 7)                        31)
      ((+ 3 6 2 3 1 0 8 9 0 3 2 4 2 5 1 0 8 3 2)  62)))

  ($test-group cycle-of-zeros
      ((cite (kernel-report 12 5 4)
             "If all the elements of a cycle are zero, the sum of the cycle is zero.")
       (number 4))
    ($check equal? (apply + (cyclic-list 0)) 0)
    ($check equal? (apply + (cyclic-list 0 0)) 0)
    ($check equal? (apply + (cyclic-list 0 0 0)) 0)
    ($check equal? (apply + (list* 2 3 (cyclic-list 0 0))) 5)))

;; div-and-mod: The defintion of div-and-mod in the Kernel Report
;; is suspicious, but it also mentions R6RS. KPLTS follows R6RS.
;;
($test-group div-and-mod
    ((cite (kernel-report 12 5 8)
           (r6rs 11 7 3 1))
     (require-standard-bindings div-and-mod)
     (plan positive-arguments r6rs division-by-zero error-handling))
  ($letrec
      ((test-case ($lambda (((x y) (q r)))
                    ($check equal?
                      (list (div x y) (mod x y) (div-and-mod x y))
                      (list q r (list q r)))))
       ($test-cases ($vau cases #ignore
                      (for-each test-case cases))))
    ($test-group positive-arguments
        ((number 2))
      ($test-cases
        ((10 5) (2 0))
        ((5678 1234) (4 742))))
    ($test-group r6rs
        ((number 17))
      ($test-cases
        ;; examples from R6RS
        (( 123 10) ( 12 3))  (( 123 -10) (-12 3))
        ((-123 10) (-13 7))  ((-123 -10) ( 13 7))
        ;; more test cases
        (( 8  8) ( 1  0))  (( 5  3) ( 1  2))
        (( 2  7) ( 0  2))  (( 0  1) ( 0  0))
        ((-2  2) (-1  0))  ((-3  5) (-1  2))
        ((-7  6) (-2  5))  (( 5 -3) (-1  2))
        (( 4 -4) (-1  0))  (( 4 -9) ( 0  4))
        ((-7 -6) ( 2  5))  ((-7 -7) ( 1  0))
        ((-7 -8) ( 1  1))))
    ($test-group division-by-zero
        ((cite (kernel-report 12 5 8)
               "if real2 is zero, an error is signaled")
         (number 5))
      ($check-error (div-and-mod 0 0))
      ($check-error (div-and-mod 1 0))
      ($check-error (div-and-mod -1 0))
      ($check-error (div 5 0))
      ($check-error (mod -9 0)))
    ($test-group error-handling
        ((number 30))
      ($let ((valid-argument-list?
              ($lambda (x)
                ($and? (pair? x) (pair? (cdr x)) (null? (cddr x))
                       (apply number? x)
                       (not? (equal? x 0))))))
      ($fuzz-applicative 10 div valid-argument-list? (10 20))
      ($fuzz-applicative 10 mod valid-argument-list? (-10 20))
      ($fuzz-applicative 10 div-and-mod valid-argument-list? (20 -20))))))

($test-group abs
    ((cite (kernel-report 12 5 12))
     (require-standard-bindings abs)
     (plan normal-operation error-handling))
  ($test-group normal-operation
      ((number 4))
    ($eval-table
      ((abs  0) 0)  ((abs    1)   1)
      ((abs -1) 1)  ((abs -128) 128)))
  ($test-group error-handling
      ((number 5))
    ($fuzz-applicative 5 abs
      ($lambda (x)
        ($and? (pair? x)
               (null? (cdr x))
               (integer? (car x))))
      (1))))

($test-group min
    ((cite (kernel-report 12 5 13))
     (require-standard-bindings min)
     (plan normal-operation cyclic-argument-list error-handling))
  ($test-group normal-operation
      ((number 10))
    ($eval-table
      ((min 0  0)  0) ((min  1 0)  0) ((min 0  1)  0) ((min  1  1)  1)
      ((min 1 -1) -1) ((min -1 0) -1) ((min 0 -1) -1) ((min -1 -1) -1)
      ((min 0) 0)
      ((min -1 0 1) -1)))
  ($test-group cyclic-argument-list
      ((require-modules pair-mutation)
       (number 2))
    ($check equal? (apply min (cyclic-list 0)) 0)
    ($check equal? (apply min (cyclic-list 10 -20 30)) -20))
  ($test-group error-handling
      ((number 20))
    ($fuzz-applicative 20 min
      ($lambda (x) ($and? (finite-list? x) (apply integer? x)))
      (1)
      (1 2)
      (1 2 3))))

($test-group max
    ((cite (kernel-report 12 5 13))
     (require-standard-bindings max)
     (plan normal-operation cyclic-argument-list error-handling))
  ($test-group normal-operation
      ((number 10))
    ($eval-table
      ((max 0  0) 0) ((max  1 0) 1) ((max 0  1) 1) ((max  1  1)  1)
      ((max 1 -1) 1) ((max -1 0) 0) ((max 0 -1) 0) ((max -1 -1) -1)
      ((max 0) 0)
      ((max -1 0 1) 1)))
  ($test-group cyclic-argument-list
      ((require-modules pair-mutation)
       (number 2))
    ($check equal? (apply max (cyclic-list 0)) 0)
    ($check equal? (apply max (cyclic-list 10 -20 30)) 30))
  ($test-group error-handling
      ((number 20))
    ($fuzz-applicative 20 max
      ($lambda (x) ($and? (finite-list? x) (apply integer? x)))
      (1)
      (1 2)
      (1 2 3))))

($test-group lcm
    ((cite (kernel-report 12 5 14))
     (require-standard-bindings lcm)
     (plan normal-operation
           negative-arguments
           nil-argument-list
           cyclic-argument-list
           error-handling))

  ($test-group normal-operation
      ((number (+ 18 21 8)))
    ($eval-table
      ((lcm   7 115) 805) ((lcm  10   7)    70) ((lcm  14  42)   42)
      ((lcm  15  60)  60) ((lcm  26  69)  1794) ((lcm  56 120)  840)
      ((lcm  66  66)  66) ((lcm  69  94)  6486) ((lcm  71 142)  142)
      ((lcm  90  42) 630) ((lcm  96  20)   480) ((lcm 104  13)  104)
      ((lcm 112  80) 560) ((lcm 118  64)  3776) ((lcm 128  64)  128)
      ((lcm 128 128) 128) ((lcm 135 101) 13635) ((lcm 137  31) 4247))
    ($eval-table
      ((lcm  1  5 12)  60) ((lcm  7 14 25)  350) ((lcm  9  9 24)   72)
      ((lcm 12  8 20) 120) ((lcm 12 24 12)   24) ((lcm 14 14 14)   14)
      ((lcm 16 16  8)  16) ((lcm 17 17 24)  408) ((lcm 18  9 27)   54)
      ((lcm 18 15  2)  90) ((lcm 19 11 16) 3344) ((lcm 22 14 10)  770)
      ((lcm 24  5  9) 360) ((lcm 25 20 15)  300) ((lcm 26 22 15) 4290)
      ((lcm 28  4 25) 700) ((lcm 28 21  1)   84) ((lcm 28 28 21)   84)
      ((lcm 29 29  8) 232) ((lcm 30  9 11)  990) ((lcm 30 15 30)   30))
    ($eval-table
      ((lcm  2  1 27 16)  432) ((lcm  6 42 10  8)  840)
      ((lcm 15 18 21  9)  630) ((lcm 16 16 24 24)   48)
      ((lcm 18 40 11 40) 3960) ((lcm 18 45 19  6) 1710)
      ((lcm 27  9 43  5) 5805) ((lcm 32 32 12  3)   96)))

  ($test-group negative-arguments
      ((number 3))
    ($eval-table
      ((lcm -1)        1)
      ((lcm 10 -15)   30)
      ((lcm -8  -4 -2) 8)))

  ($test-group nil-argument-list
      ((cite (kernel-report 12 5 14)
             "lcm with nil argument list returns 1")
       (number 1))
    ($check equal? (lcm) 1))

  ($test-group cyclic-argument-list
      ((require-modules pair-mutation)
       (number 3))
    ($letrec ((arglist ($lambda (n a)
                         ($if (positive? n)
                            (cons a (arglist (- n 1) (* 2 a)))
                            ())))
              (lengths (list 10 100 1000)))
      (for-each
        ($lambda (n)
          ($let ((args (arglist n 2)))
            (encycle! args 0 n)
            ($check equal? (apply lcm args) (apply max args))))
        lengths)))

  ($test-group error-handling
      ((number 20))
    ($fuzz-applicative 20 lcm
      ($lambda (x) ($and? (finite-list? x) (apply integer? x)))
      (1)
      (2 3)
      (4 5 6))))

($test-group gcd
    ((cite (kernel-report 12 5 14))
     (require-standard-bindings gcd)
     (plan normal-operation
           negative-arguments
           long-argument-list
           cyclic-argument-list
           error-handling))

  ($test-group normal-operation
      ((number (+ 18 26 24)))
    ($eval-table
      ((gcd   3   2)   1)  ((gcd   3  40)  1)  ((gcd  12  12) 12)
      ((gcd  27  66)   3)  ((gcd  34  68) 34)  ((gcd  36  48) 12)
      ((gcd  47 149)   1)  ((gcd  48  28)  4)  ((gcd  49 138)  1)
      ((gcd  80  21)   1)  ((gcd  80 128) 16)  ((gcd  96 136)  8)
      ((gcd 113  50)   1)  ((gcd 125  16)  1)  ((gcd 128  64) 64)
      ((gcd 128 128) 128)  ((gcd 134   8)  2)  ((gcd 143  96)  1))
    ($eval-table
      ((gcd  2 27  3)  1)  ((gcd  4 20 21)  1)
      ((gcd  5 10 18)  1)  ((gcd  8  8 24)  8)
      ((gcd  9 27 27)  9)  ((gcd 11 22 11) 11)
      ((gcd 12  9 17)  1)  ((gcd 13  5 16)  1)
      ((gcd 13 14 12)  1)  ((gcd 13 26 13) 13)
      ((gcd 16 16 21)  1)  ((gcd 17 13  1)  1)
      ((gcd 20 20  4)  4)  ((gcd 20 20 30) 10)
      ((gcd 20 22 22)  2)  ((gcd 21 10  9)  1)
      ((gcd 21 14  7)  7)  ((gcd 24  8 18)  2)
      ((gcd 24 12 24) 12)  ((gcd 25 15 20)  5)
      ((gcd 27  8  4)  1)  ((gcd 27 15 24)  3)
      ((gcd 27 19 12)  1)  ((gcd 28 14 14) 14)
      ((gcd 30 12 24)  6)  ((gcd 30 30 15) 15))
   ($eval-table
      ((gcd   6 120 342 150)  6) ((gcd  14 168 406 308) 14)
      ((gcd  32 400 144 128) 16) ((gcd  80 272 120 472)  8)
      ((gcd 100 380  90 430) 10) ((gcd 150  45 135 225) 15)
      ((gcd 158 250 249 150)  1) ((gcd 171 152  19 304) 19)
      ((gcd 189 336 126 357) 21) ((gcd 225 180 252  90)  9)
      ((gcd 264 286  44 242) 22) ((gcd 301 129 172 258) 43)
      ((gcd 306  18  54 414) 18) ((gcd 340  20  80  20) 20)
      ((gcd 350 280 175 210) 35) ((gcd 357 498  84  72)  3)
      ((gcd 374 221 289  85) 17) ((gcd 403 208 299 286) 13)
      ((gcd 405  90 295 325)  5) ((gcd 432 364  32 480)  4)
      ((gcd 446 136 318 260)  2) ((gcd 468  36 456 336) 12)
      ((gcd 484 396 121 484) 11) ((gcd 490  84 266   7)  7)))

  ($test-group negative-arguments
      ((number 3))
    ($eval-table
      ((gcd -1)        1)
      ((gcd 10 -15)    5)
      ((gcd -8  -4 -2) 2)))

  ($letrec ((arglist ($lambda (n a)
                        ($if (positive? n)
                          (cons a (arglist (- n 1) a))
                          ())))
            (lengths (list 10 100 1000)))
    ($test-group long-argument-list
        ((number 3))
      (for-each
        ($lambda (n) ($check equal? (apply gcd (arglist n 2)) 2))
        lengths))
    ($test-group cyclic-argument-list
      ((require-modules pair-mutation)
       (number 3))
      (for-each
        ($lambda (n)
          ($let ((args (arglist n 2)))
            (encycle! args 0 n)
            ($check equal? (apply gcd args) 2)))
        lengths)))

  ($test-group error-handling
      ((number 20))
    ($fuzz-applicative 20 gcd
      ($lambda (x) ($and? (finite-list? x) (apply integer? x)))
      (1)
      (2 3)
      (4 5 6))))


