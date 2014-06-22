;;;
;;; numbers.k
;;;
;;; Test of numeric features.
;;;
;;; This file should not contain any numeric literals except small integers.
;;; Tests of advanced number syntax like fractions and complex numbers
;;; should be loaded separately.
;;;

($test-group numbers
     ((cite (kernel-report 12))
      (plan small-integers
            big-integers
            exact-infinities
            ratios
            real-numbers
            inexact-numbers
            complex-numbers))
  ($define! sub-plan
    ($quote (plan + - *
                  div mod div-and-mod
                  div0 mod0 div0-and-mod0
                  abs min max
                  lcm gcd)))
  (for-each
    ($lambda ((sym . meta))
      ((wrap $test-group) sym (cons sub-plan meta)
              (list load
                    (string-append "arithmetic/" (symbol->string sym) ".k"))))
    ($quote ((small-integers)
             (big-integers)
             (exact-infinities)
             (ratios           (require-modules rational))
             (real-numbers     (require-modules real))
             (inexact-numbers  (require-modules inexact))
             (complex-numbers  (require-modules complex))))))
