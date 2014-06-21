;;;
;;; arithmetic/exact-infinities.k
;;;
;;; Test arithmetic operations with exact infinite arguments and/or results.
;;;
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

