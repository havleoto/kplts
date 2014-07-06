;;;
;;; parse-options.k
;;;
;;; Parse options passed to the run script on the command line,
;;; see klisp-compatibility.k for example of use.
;;;
;;; (string->object STR) => OBJECT
;;; ($parse-options ARGV (NAME . DEFAULT-VALUE) ...) => ENVIRONMENT
;;;

($define! string->object
  ($lambda (s)
    (read (open-input-string s))))

($define! $parse-options
  ($vau (argv . defs) denv
    ($define! parsers (make-environment))
    ($define! values (make-environment))
    ($define! parse
      ($lambda (argv)
        ($if (null? argv)
          values
          (parse ((guard-dynamic-extent
                   ()
                   ($lambda () (eval (string->symbol (car argv)) parsers))
                   (list (list error-continuation
                               ($lambda (obj divert)
                                 (error "Invalid command line option." (car argv))))))
                 argv)))))
    (for-each
      ($lambda ((name expr))
        (eval (list $set! values name expr) denv)
        ((wrap $set!)
          parsers
          (string->symbol (string-append "-" (symbol->string name)))
          ($cond
            ((eq? expr #f)
              ($lambda (argv)
                ((wrap $set!) values name #t)
                (cdr argv)))
            (#t
              ($lambda (argv)
                ($unless (pair? (cdr argv))
                  (display "Missing command-line option argument: ")
                  (display argv)
                  (newline)
                  (exit 1))
                ((wrap $set!) values
                              name
                              (list string->object (cadr argv)))
                (cddr argv))))))
      defs)
   (parse (eval argv denv))))
