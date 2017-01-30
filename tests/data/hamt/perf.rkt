#lang racket/base

(require data/hamt
         (prefix-in f: data/hamt/fast)
         racket/syntax
         (for-syntax racket/base))

(define (random-key)
  (list->string
   (map integer->char
        (for/list ([i (in-range 1 (add1 (random 20)))])
          (random 256)))))


(define N 500000)


(define (gc)
  (collect-garbage)
  (collect-garbage)
  (collect-garbage))

(define-syntax-rule (run keys kons set ref remove)
  (begin
    (printf "\n")
    (printf " - ~a\n" 'kons)
    (printf " -- insertion\n") (gc)  
    (let ([h (time (for/fold ([h (kons)]) ([k (in-list keys)]) (set h k #t)))])
      (printf " -- lookup\n") (gc)
      (time (for ([k (in-list keys)]) (ref h k)))
      (printf " -- removal\n") (gc)
      (void (time (for/fold ([h h]) ([k (in-list keys)]) (remove h k)))))))

(printf "1. random string keys [equal?]\n")
(let ([keys (for/list ([i N]) (random-key))])
  (run keys hash hash-set hash-ref hash-remove)
  (run keys hamt hamt-set hamt-ref hamt-remove)
  (run keys f:hamt f:hamt-set f:hamt-ref f:hamt-remove))

(printf "\n2. sequential integer keys [eqv?]\n")
(let ([keys (for/list ([i (in-range N)]) i)])
  (run keys hasheqv hash-set hash-ref hash-remove)
  (run keys hamteqv hamt-set hamt-ref hamt-remove)
  (run keys f:hamteqv f:hamt-set f:hamt-ref f:hamt-remove))
  
(printf "\n3. random integer keys [eqv?]\n")
(let ([keys (for/list ([i (in-range N)]) (random 1000000000))])
  (run keys hasheqv hash-set hash-ref hash-remove)
  (run keys hamteqv hamt-set hamt-ref hamt-remove)
  (run keys f:hamteqv f:hamt-set f:hamt-ref f:hamt-remove))

(printf "\n4. random symbol keys [eq?]\n")
(let ([keys (for/list ([i (in-range N)]) (string->symbol (random-key)))])
  (run keys hasheq hash-set hash-ref hash-remove)
  (run keys hamteq hamt-set hamt-ref hamt-remove)
  (run keys f:hamteq f:hamt-set f:hamt-ref f:hamt-remove))
