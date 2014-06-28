;;;
;;; arithmetic/exact-infinities.k
;;;
;;; Test arithmetic operations with exact infinite arguments and/or results.
;;;

($test-group +
    ((cite (kernel-report 12 5 4))
     (require-standard-bindings +)
     (plan finite-argument-list cyclic-argument-list))
   ($test-group finite-argument-list
       ((number 7))
     ($eval-table
       ((+ #e+infinity) #e+infinity)
       ((+ #e-infinity) #e-infinity)
       ((+ #e+infinity         123) #e+infinity)
       ((+ #e+infinity #e+infinity) #e+infinity)
       ((+ #e-infinity #e-infinity) #e-infinity)
       ((+         123 #e-infinity) #e-infinity)
       ((+ #e-infinity #e-infinity #e-infinity) #e-infinity)))
   ;; XXX don't know what to expect from (+ #e+infinity . #1=(1 -1 . #1#))
   ($test-group cyclic-argument-list
       ((cite (kernel-report 12 5 4)
              "If the acyclic sum of the elements of a cycle (i.e., the sum
               of an acyclic list containing just those elements) is non-zero,
               the sum of the cycle is positive infinity times the acyclic sum
               of the elements.")
        (number 4))
     ($check equal? (apply + (cyclic-list 1)) #e+infinity)
     ($check equal? (apply + (cyclic-list -1)) #e-infinity)
     ($check equal? (apply + (cyclic-list 1 -2 3)) #e+infinity)
     ($check equal? (apply + (cyclic-list -5 10 -6)) #e-infinity)))

($test-group div-and-mod
    ((cite (kernel-report 12 5 8))
     (plan infinite-dividend infinite-divisor))
  ($test-group infinite-dividend
       ((cite (kernel-report 12 5 8)
              "if real1 is infinite or real2 is zero, an error is signaled")
        (number 6))
    ($check-error (div-and-mod #e+infinity 2))
    ($check-error (div-and-mod #e-infinity 1))
    ($check-error (div #e+infinity 42))
    ($check-error (div #e-infinity #e+infinity))
    ($check-error (mod #e+infinity 0))
    ($check-error (mod #e-infinity -5)))
  ;; XXX Don't know what to expect from (div-and-mod x #e+infinity)
  ;($test-group infinite-divisor
  ;    ((number 4))
  ;  ($check equal? (div-and-mod  10 #e+infinity) (0 10))
  ;  ($check equal? (div-and-mod -10 #e+infinity) (-1 #e+infinity))
  ;  ($check equal? (div-and-mod  10 #e-infinity) (0 10))
  ;  ($check equal? (div-and-mod -10 #e-infinity) (1 #e+infinity)))
)

($test-group abs
    ((cite (kernel-report 12 5 12))
     (require-standard-bindings abs)
     (number 2))
  ($eval-table
    ((abs #e+infinity) #e+infinity)
    ((abs #e-infinity) #e+infinity)))

($test-group min
    ((cite (kernel-report 12 5 13))
     (require-standard-bindings min)
     (plan normal-operation empty-argument-list))
  ($test-group normal-operation
      ((number 8))
    ($eval-table
      ((min #e+infinity #e+infinity) #e+infinity)
      ((min #e-infinity #e+infinity) #e-infinity)
      ((min #e+infinity #e-infinity) #e-infinity)
      ((min #e-infinity #e-infinity) #e-infinity)
      ((min           0 #e+infinity)           0)
      ((min           0 #e-infinity) #e-infinity)
      ((min        -999 #e+infinity)        -999)
      ((min        -999 #e-infinity) #e-infinity)))
  ($test-group empty-argument-list
      ((cite (kernel-report 12 5 13)
             "If reals is nil [...] min returns exact positive infinity.")
       (number 1))
    ($check equal? (min) #e+infinity)))

($test-group max
    ((cite (kernel-report 12 5 13))
     (require-standard-bindings max)
     (plan normal-operation empty-argument-list))
  ($test-group normal-operation
      ((number 8))
    ($eval-table
      ((max #e+infinity #e+infinity) #e+infinity)
      ((max #e-infinity #e+infinity) #e+infinity)
      ((max #e+infinity #e-infinity) #e+infinity)
      ((max #e-infinity #e-infinity) #e-infinity)
      ((max           0 #e+infinity) #e+infinity)
      ((max           0 #e-infinity)           0)
      ((max        -999 #e+infinity) #e+infinity)
      ((max        -999 #e-infinity)        -999)))
  ($test-group empty-argument-list
      ((cite (kernel-report 12 5 13)
             "If reals is nil, applicative max returns exact negative infinity")
       (number 1))
    ($check equal? (max) #e-infinity)))

($test-group lcm
    ((cite (kernel-report 12 5 14)
           "lcm with any infinite argument returns positive infinity")
     (require-standard-bindings lcm)
     (number 6))
  ($eval-table
    ((lcm #e+infinity) #e+infinity)
    ((lcm -5 #e+infinity) #e+infinity)
    ((lcm 2 3 #e+infinity) #e+infinity)
    ((lcm #e+infinity #e+infinity) #e+infinity)
    ((lcm #e-infinity #e+infinity) #e+infinity)
    ((lcm #e-infinity #e-infinity #e-infinity) #e+infinity)))

($test-group gcd
    ((cite (kernel-report 12 5 14))
     (require-standard-bindings gcd)
     (plan nil delete-infinities))
  ($test-group nil
      ((cite (kernel-report 12 5 14)
             "gcd with nil argument list returns exact positive infinity")
       (number 1))
    ($eval-table
      ((gcd) #e+infinity)))
  ($test-group delete-infinities
      ((cite (kernel-report 12 5 14)
             "if gcd is called with at least one finite non-zero argument,
              its result is the same as if all zero and infinite arguments
              were deleted.")
       (number 4))
    ($eval-table
      ((gcd 1 #e+infinity) 1)
      ((gcd 1 #e-infinity) 1)
      ((gcd 0 5 0 #e+infinity) 5)
      ((gcd #e+infinity 12 #e-infinity 15) 3))))

