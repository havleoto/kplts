;;;
;;; ratios.k
;;;
;;; Test arithmetic operations with rational numbers (fractions).
;;;

($test-group abs
    ((cite (kernel-report 12 5 14))
     (require-standard-bindings abs)
     (number 2))
  ($eval-table
    ((abs -4/5) 4/5)
    ((abs 13/26) 1/2)))

($test-group min
    ((cite (kernel-report 12 5 13))
     (require-standard-bindings min)
     (number 2))
  ($eval-table
    ((min 1/2 1/3) 1/3)
    ((min -22/7 -314/100) -22/7)))

($test-group max
    ((cite (kernel-report 12 5 13))
     (require-standard-bindings max)
     (number 2))
  ($eval-table
    ((max 1/2 1/3) 1/2)
    ((max -22/7 -314/100) -314/100)))

;; LCM and GCD: The Kernel Report defines LCM and GCD only for integer
;; arguments (although the mathematical functions can be extended
;; to non-integer arguments). In the tests, I just pass integers
;; expressed as ratios.
;;

($test-group lcm
    ((cite (kernel-report 12 5 14))
     (require-standard-bindings lcm)
     (number 2))
  ($eval-table
    ((lcm 10/5 12/3) 4)
    ((lcm 5600/100 -12000/100) 84000/100)))

($test-group gcd
    ((cite (kernel-report 12 5 14))
     (require-standard-bindings gcd)
     (number 2))
  ($eval-table
    ((gcd 10/5 12/3) 2)
    ((gcd -18/6 9) 3)))
