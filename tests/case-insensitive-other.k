;;;
;;; case-insensitive-other.k
;;;
;;; See comments for test group case-insensitivity in lexemes.k.
;;;
($test-group other
    ((number 4))
  ($check equal? #t #T)
  ($check equal? #f #F)
  ($check equal? #ignore #IGNoRE)
  ($check equal? #inert #INeRT))
