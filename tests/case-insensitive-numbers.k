;;;
;;; case-insensitive-numbers.k
;;;
;;; See comments for test group case-insensitivity in lexemes.k.
;;;
($test-group numbers
    ((number 3))
  ($check equal? #x1AB #X1ab)
  ($check equal? #e123 #E123)
  ($check equal? #e+infinity #E+iNfInItY))
