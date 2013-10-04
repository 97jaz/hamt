#lang racket/base

(require data/hamt)

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

(printf "1. random string keys [equal?]\n")
(let ([keys (for/list ([i N]) (random-key))])
  
  (printf " - hash\n")
  (printf " -- insertion\n") (gc)  
  (let ([h (time (for/fold ([h (hash)]) ([k (in-list keys)]) (hash-set h k #t)))])
    (printf " -- lookup\n") (gc)
    (time (for ([k (in-list keys)]) (hash-ref h k)))
    (printf " -- removal\n") (gc)
    (void (time (for/fold ([h h]) ([k (in-list keys)]) (hash-remove h k)))))
  
  (printf "\n")
  (printf " - hamt\n")
  (printf " -- insertion\n") (gc)
  (let ([h (time (for/fold ([h (hamt)]) ([k (in-list keys)]) (hamt-set h k #t)))])
    (printf " -- lookup\n") (gc)
    (time (for ([k (in-list keys)]) (hamt-ref h k)))
    (printf " -- removal\n") (gc)
    (void (time (for/fold ([h h]) ([k (in-list keys)]) (hamt-remove h k))))))


(printf "\n2. sequential integer keys [eqv?]\n")
(let ([keys (for/list ([i (in-range N)]) i)])
  (printf " - hash\n")
  (printf " -- insertion\n") (gc)
  (let ([h (time (for/fold ([h (hasheqv)]) ([k (in-list keys)]) (hash-set h k #t)))])
    (printf " -- lookup\n") (gc)
    (time (for ([k (in-list keys)]) (hash-ref h k)))
    (printf " -- removal\n") (gc)
    (void (time (for/fold ([h h]) ([k (in-list keys)]) (hash-remove h k)))))
  
  (printf "\n")
  (printf " - hamt\n")
  (printf " -- insertion\n") (gc)
  (let ([h (time (for/fold ([h (hamteqv)]) ([k (in-list keys)]) (hamt-set h k #t)))])
    (printf " -- lookup\n") (gc)
    (time (for ([k (in-list keys)]) (hamt-ref h k)))
    (printf " -- removal\n") (gc)
    (void (time (for/fold ([h h]) ([k (in-list keys)]) (hamt-remove h k))))))

(printf "\n3. random integer keys [eqv?]\n")
(let ([keys (for/list ([i (in-range N)]) (random 1000000000))])
  (printf " - hash\n")
  (printf " -- insertion\n") (gc)
  (let ([h (time (for/fold ([h (hasheqv)]) ([k (in-list keys)]) (hash-set h k #t)))])
    (printf " -- lookup\n") (gc)
    (time (for ([k (in-list keys)]) (hash-ref h k)))
    (printf " -- removal\n") (gc)
    (void (time (for/fold ([h h]) ([k (in-list keys)]) (hash-remove h k)))))
  
  (printf "\n")
  (printf " - hamt\n")
  (printf " -- insertion\n") (gc)
  (let ([h (time (for/fold ([h (hamteqv)]) ([k (in-list keys)]) (hamt-set h k #t)))])
    (printf " -- lookup\n") (gc)
    (time (for ([k (in-list keys)]) (hamt-ref h k)))
    (printf " -- removal\n") (gc)
    (void (time (for/fold ([h h]) ([k (in-list keys)]) (hamt-remove h k))))))

(printf "\n4. random symbol keys [eq?]\n")
(let ([keys (for/list ([i (in-range N)]) (string->symbol (random-key)))])
  (printf " - hash\n")
  (printf " -- insertion\n") (gc)
  (let ([h (time (for/fold ([h (hasheq)]) ([k (in-list keys)]) (hash-set h k #t)))])
    (printf " -- lookup\n") (gc)
    (time (for ([k (in-list keys)]) (hash-ref h k)))
    (printf " -- removal\n") (gc)
    (void (time (for/fold ([h h]) ([k (in-list keys)]) (hash-remove h k)))))
  
  (printf "\n")
  (printf " - hamt\n")
  (printf " -- insertion\n") (gc)
  (let ([h (time (for/fold ([h (hamteq)]) ([k (in-list keys)]) (hamt-set h k #t)))])
    (printf " -- lookup\n") (gc)
    (time (for ([k (in-list keys)]) (hamt-ref h k)))
    (printf " -- removal\n") (gc)
    (void (time (for/fold ([h h]) ([k (in-list keys)]) (hamt-remove h k))))))

