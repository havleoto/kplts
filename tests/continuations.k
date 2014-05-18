;;;
;;; continuations.k
;;;

($test-group continuations
    ((cite (kernel-report 7))
     (plan selection
           interception
           combiners))

  ($test-group selection
      ((plan entry-guards exit-guards all-guards)
       (require-standard-bindings extend-continuation guard-continuation
                                  apply-continuation $let/cc)
       (cite (kernel-report 7 2 5)))
    ($define! $defc!
      ($vau (name entry-targets parent exit-targets) denv
        (set! denv name
          (guard-continuation
            (map
              ($lambda (target)
                (list (eval target denv)
                      ($lambda (obj #ignore) (cons (list +1 name target) obj))))
              entry-targets)
            (eval parent denv)
            (map
              ($lambda (target)
                (list (eval target denv)
                      ($lambda (obj #ignore) (cons (list -1 name target) obj))))
              exit-targets)))))
    ($define! $jump
      ($vau (src dst . expected-guards) denv
        ($let/cc ret
          ($define! dst+1
            (extend-continuation (eval dst denv)
                                 ($lambda x
                                   ($check equal? (reverse x) expected-guards)
                                   (apply-continuation ret ()))))
          ($define! src+1
            (extend-continuation (eval src denv)
                                 ($lambda #ignore
                                   (apply-continuation dst+1 ()))))
          (apply-continuation src+1 ()))
        #inert))

    ;;
    ;;       k
    ;;       a
    ;;    b    e
    ;;   c d  f g
    ;;

    ($test-group entry-guards
        ((number 7))
      ($let/cc k
        ($define! a (extend-continuation k ($lambda #ignore #inert)))
        ($defc! b (a) a ())
        ($defc! c (b a) b ())
        ($defc! d (c b a) b ())
        ($defc! e (d c b a) a ())
        ($defc! f (e d c b a) e ())
        ($defc! g (f e d c b a) e ())
        ($jump c b)
        ($jump b c (+1 c b))
        ($jump c d (+1 d c))
        ($jump d c (+1 c b))
        ($jump c g (+1 e c) (+1 g c))
        ($jump g c (+1 b a) (+1 c a))
        ($jump e b (+1 b a))))

    ($test-group exit-guards
        ((number 7))
      ($let/cc k
        ($define! a (extend-continuation k ($lambda #ignore #inert)))
        ($defc! b () a (a))
        ($defc! c () b (b a))
        ($defc! d () b (c b a))
        ($defc! e () a (d c b a))
        ($defc! f () e (e d c b a))
        ($defc! g () e (f e d c b a))
        ($jump c b (-1 c b))
        ($jump b c)
        ($jump c d (-1 c b))
        ($jump d c (-1 d c))
        ($jump c g (-1 c a) (-1 b a))
        ($jump g c (-1 g c) (-1 e c))
        ($jump e b (-1 e b))))

    ($test-group all-guards
        ((number 7))
      ($let/cc k
        ($define! a (extend-continuation k ($lambda #ignore #inert)))
        ($defc! b (a) a (a))
        ($defc! c (b a) b (b a))
        ($defc! d (c b a) b (c b a))
        ($defc! e (d c b a) a (d c b a))
        ($defc! f (e d c b a) e (e d c b a))
        ($defc! g (f e d c b a) e (f e d c b a))
        ($jump c b (-1 c b))
        ($jump b c (+1 c b))
        ($jump c d (-1 c b) (+1 d c))
        ($jump d c (-1 d c) (+1 c b))
        ($jump c g (-1 c a) (-1 b a) (+1 e c) (+1 g c))
        ($jump g c (-1 g c) (-1 e c) (+1 b a) (+1 c a))
        ($jump e b (-1 e b) (+1 b a)))))

  ($test-group combiners
     ((plan call/cc
           extend-continuation
           guard-continuation
           continuation->applicative
           root-continuation
           error-continuation
           apply-continuation
           $let/cc
           guard-dynamic-extent
           exit))
    ($test-group guard-continuation
        ((cite (kernel-report 7 2 4))
         (plan selection interception))
      #inert)))
