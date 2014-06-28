;;;
;;; ratios.k
;;;
;;; Test arithmetic operations with rational numbers (fractions).
;;;

($test-group +
    ((cite (kernel-report 12 5 4)
           "Applicative + returns the sum of the elements of /numbers/.")
     (require-standard-bindings +)
     (plan random-inputs finite-argument-list))
  ($test-group random-inputs
      ((number 30))
    ($eval-table
      ((+ -16/20 -21/42)  -13/10)  ((+  25/31  -1/12) 269/372)
      ((+ -26/43  15/43)  -11/43)  ((+  -40/9   0/39)   -40/9)
      ((+  -6/44  31/41) 559/902)  ((+  45/33  36/22)       3)
      ((+   0/38 -32/27)  -32/27)  ((+  -8/36  23/36)    5/12)
      ((+  11/39  25/39)   12/13)  ((+ -18/48   0/29)    -3/8)
      ((+   2/38  14/38)    8/19)  ((+  -9/15   0/31)    -3/5)
      ((+   6/25  48/27) 454/225)  ((+  -4/12  25/15)     4/3)
      ((+ -38/37   0/30)  -38/37)  ((+   0/29    2/2)       1)
      ((+  16/16 -10/40)     3/4)  ((+  25/18   10/9)     5/2)
      ((+   0/47  46/40)   23/20)  ((+   0/11  35/14)     5/2)
      ((+  40/35  22/33)   38/21)  ((+  20/15  26/13)    10/3)
      ((+  20/24 -23/46)     1/3)  ((+  32/13   0/34)   32/13)
      ((+  37/31 -19/19)    6/31)  ((+  37/37   45/5)      10)
      ((+  41/29   4/12)  152/87)  ((+  18/38 -28/19)      -1)
      ((+  27/22  12/44)     3/2)  ((+  -4/32 -21/28)    -7/8)))
  ($test-group finite-argument-list
      ((number 1))
    ($eval-table
      ((+ 1 1/4 1/9 1/16 1/25 1/36 1/49 1/64
          1/81 1/100 1/121 1/144 1/169 1/196
          1/225 1/256 1/289 1/324 1/361 1/400)
       17299975731542641/10838475198270720))))

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
