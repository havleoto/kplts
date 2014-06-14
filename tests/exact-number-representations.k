;;;
;;; exact-number-representations.k
;;;
;;; See comments for test group exact-number-representations in lexemes.k.
;;;
    ($check (number? 0))
    ($check (number? -0))
    ($check (number? #b1))
    ; exactness and base prefix can go in either order.
    ($check (number? #b#e01))
    ($check (number? #e#d1))
    ($check (number? #e+infinity))
    ($check (number? #e-infinity))
    ($check (number? #e#b10))
    ($check (number? #X1cC))
    ($check (number? #xeee))
    ($check (number? #e#o12345670))
    ; negative non-decimal
    ($check (number? #e#b-10))
    ($check (number? #x-deadbeef))
    ($check (number? #e#o-4))
    ; bignums
    ($check (number? 999999999999999999999999999999999999999999999999999999999999999))
    ($check (number? #b1111111111111111111111111111111111111111111111111111111111111111111111111111))
    ($check (number? #o7777777777777777777777777777777777777777777777777777777777777777777))
    ($check (number? #xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff))
