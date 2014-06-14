($test-group lexemes
    ((cite (kernel-report 2))
     (plan case-insensitivity
           identifiers
           whitespace
           comments
           exact-number-representations
           other-notations
           reserved-notations))

  ($test-group case-insensitivity
      ((cite (kernel-report 2)
             "Upper and lower case forms of a letter are never distinguished
             except within character and string constants.")
       (plan identifiers numbers other))
    ($test-group identifiers
         ((number 1))
      (($vau (x y) #ignore ($check equal? x y)) iDentiFier IdenTIfier))
    ;;
    ;; Subgroups are put in separate files in order to keep failures
    ;; localized. Otherwise, non-conforming case sensitive interpreters
    ;; could refuse to parse the whole file lexemes.k.
    ;;
    (load "case-insensitive-numbers.k")
    (load "case-insensitive-other.k"))

  ($test-group identifiers
      ((cite (kernel-report 2 1))
       (number 3))
    ($check ((unwrap symbol?) +))
    ($check ((unwrap symbol?) -))
    ; extended alphabetic characters
    ($check ((unwrap symbol?) !$%&*+-./:<=>?@^_~)))

  ($test-group whitespace
      ((cite (kernel-report 2 2)
             "Whitespace characters are spaces and newlines")
       (number 1))
    ($check equal? (list 1 2)
                   (list 1
2)))

  ($test-group comments
      ((cite (kernel-report 2 2)
             "Comments are invisible to Kernel, but the end of the line is
             visible as whitespace.  This prevents a comment from appearing in
             the middle of an identifier or number.")
       (number 2))
    ($check equal? (list 1 2)
                   (list 1;comment
2))
    ($check equal? ((unwrap list) a b)
                   ((unwrap list) a;comment
b)))

  ($test-group exact-number-representations
      ((cite (kernel-report 12 4))
       (number 18))
    ;;
    ;; The tested syntax is put in a separate file in order to keep failures
    ;; localized. Otherwise, non-conforming interpreters could refuse to
    ;; parse the whole file lexemes.k.
    ;;
    (load "exact-number-representations.k"))

  ($test-group other-notations
      ((cite (kernel-report 2 3))
       (number 4))
    ($check (not? ((unwrap symbol?) #t)))
    ($check (not? ((unwrap symbol?) #f)))
    ($check (not? ((unwrap symbol?) #ignore)))
    ($check (not? ((unwrap symbol?) #inert))))

  ($test-group reserved-notations
      ((cite (kernel-report 2 3)
             "[ ] { } |  (...) are reserved for possible future use in the
             language.
             ' ` , ,@  (...) are reserved as illegal lexemes (...).")
             (number 22))
    (for-each
      ($lambda (name)
        ($check-error
          (load (string-append "reserved-notations/" name ".k"))))
      (list "empty-balanced-brackets"
            "nonempty-balanced-brackets"
            "left-bracket-in-identifier"
            "right-bracket-in-identifier"
            "empty-balanced-braces"
            "nonempty-balanced-braces"
            "left-brace-in-identifier"
            "right-brace-in-identifier"
            "standalone-vertical-bar"
            "vertical-bar-in-identifier"
            "vertical-bar-around-identifier"
            "standalone-quote"
            "quote-before-identifier"
            "quote-in-identifier"
            "standalone-backquote"
            "backquote-in-identifier"
            "standalone-comma"
            "comma-in-identifier"
            "unquoting-comma"
            "standalone-comma-at"
            "comma-at-in-identifier"
            "splicing-comma-at"))))
