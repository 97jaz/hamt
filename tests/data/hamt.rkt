#lang racket/base

(require racket/match
         rackunit
         data/hamt)

;; hamt[eqv, eq] constructor and predicates
(let ([h (hamt)])
  (check-true (hamt? h))
  (check-true (hamt-equal? h)))
(let ([h (hamteqv)])
  (check-true (hamt? h))
  (check-true (hamt-eqv? h)))
(let ([h (hamteq)])
  (check-true (hamt? h))
  (check-true (hamt-eq? h)))

(check-true (hamt? (hamt 1 2)))
(check-true (hamt? (hamt 'foo "foo"
                         'bar "bar"
                         'baz "baz")))
(check-exn exn:fail:contract? (λ () (hamt 1)))
(check-exn exn:fail:contract? (λ () (hamt 1 2 3 4 5)))

;; make-hamt[eqv, eq] constructor
(check-true (hamt? (make-hamt)))
(check-true (hamt? (make-hamteqv)))
(check-true (hamt? (make-hamteq)))
(check-true (hamt? (make-hamt '((foo . "foo") (bar . "bar") (baz . "baz")))))
(check-exn exn:fail:contract? (λ () (make-hamt 1 2)))

;; hamt? (positive cases are checked all over these tests)
(check-false (hamt? #t))
(check-false (hamt? '(foo bar)))

;; hamt-count
(define (hamt-of-size n)
  (for/fold ([h (hamteq)]) ([i (in-range n)])
    (hamt-set h i (number->string i))))

(check-eqv? (hamt-count (hamt-of-size 0)) 0)
(check-eqv? (hamt-count (hamt-of-size 1)) 1)
(check-eqv? (hamt-count (hamt-of-size 2)) 2)
(check-eqv? (hamt-count (hamt-of-size 10)) 10)
(check-eqv? (hamt-count (hamt-of-size 100)) 100)

;; hamt-empty?
(check-true (hamt-empty? (hamt-of-size 0)))
(check-false (hamt-empty? (hamt-of-size 1)))

;; hamt-has-key?
(define string-key "foo")
(define bignum-key 999999999999999999999999999999999)
(define symbol-key 'foo)

(define args (list string-key "string"
                   bignum-key "bignum"
                   symbol-key "symbol"))

(let ([h (apply hamt args)])
  (check-true (hamt-has-key? h (string-copy string-key)))
  (check-true (hamt-has-key? h (string->number (number->string bignum-key))))
  (check-true (hamt-has-key? h symbol-key))
  (check-false (hamt-has-key? h 'something-else)))

(let ([h (apply hamteqv args)])
  (check-true (hamt-has-key? h string-key))
  (check-false (hamt-has-key? h (string-copy string-key)))
  (check-true (hamt-has-key? h (string->number (number->string bignum-key))))
  (check-true (hamt-has-key? h symbol-key))
  (check-false (hamt-has-key? h 'something-else)))

(let ([h (apply hamteq args)])
  (check-true (hamt-has-key? h string-key))
  (check-false (hamt-has-key? h (string-copy string-key)))
  (check-true (hamt-has-key? h bignum-key))
  (check-false (hamt-has-key? h (string->number (number->string bignum-key))))
  (check-true (hamt-has-key? h symbol-key))
  (check-false (hamt-has-key? h 'something-else)))

;; hamt-ref
(let ([h (hamt-of-size 32)])
  (check-equal? (hamt-ref h 0) "0")
  (check-equal? (hamt-ref h 7) "7")
  (check-equal? (hamt-ref h 31) "31")
  (check-exn exn:fail:contract? (λ () (hamt-ref h 'foo)))
  (check-false (hamt-ref h 'foo #f))
  (check-equal? '(*foo*) (hamt-ref h "blah" '(*foo*))))

;; hamt-set
(let* ([h0  (hamt)]
       [h1a (hamt-set h0 'foo "foo")]
       [h1b (hamt-set h0 'foo "not-foo")]
       [h2  (hamt-set h1a 'bar "bar")])
  (check-true (hamt-empty? h0))
  (check-eqv? (hamt-count h1a) 1)
  (check-eqv? (hamt-count h1b) 1)
  (check-eqv? (hamt-count h2) 2)
  
  (check-false (hamt-ref h0 'foo #f))
  (check-equal? (hamt-ref h1a 'foo) "foo")
  (check-equal? (hamt-ref h1b 'foo) "not-foo")
  (check-equal? (hamt-ref h2 'foo) "foo")
  (check-equal? (hamt-ref h2 'bar) "bar"))

;; hamt-set*
(let ([h (hamt-set* (hamt) 'foo "foo" 'bar "bar")])
  (check-equal? (hamt-ref h 'foo) "foo")
  (check-equal? (hamt-ref h 'bar) "bar")
  (check-false (hamt-ref h 'baz #f)))

(check-exn exn:fail:contract? (λ () (hamt-set* (hamt) 'foo)))

;; hamt-remove
(let* ([h3 (hamt 'foo "foo"
                 'bar "bar"
                 'baz "baz")]
       [h2 (hamt-remove h3 'bar)]
       [h1 (hamt-remove h2 'foo)]
       [h0 (hamt-remove h1 'baz)])
  (check-eqv? (hamt-count h3) 3)
  (check-eqv? (hamt-count h2) 2)
  (check-eqv? (hamt-count h1) 1)
  (check-eqv? (hamt-count h0) 0)
  (check-false (hamt-has-key? h2 'bar))
  (check-false (hamt-has-key? h1 'foo)))

;; hamt-map
(define foobarbaz '((foo . "foo") (bar . "bar") (baz . "baz")))
(define fbb-hamt (make-hamt foobarbaz))

(check-equal? (sort (hamt-map fbb-hamt
                              (λ (k v) (string-upcase v)))
                    string<?)
              '("BAR" "BAZ" "FOO"))

;; hamt-for-each
(let ([vec (vector #f #f #f)])
  (hamt-for-each (hamt 0 'a 1 'b '2 'c)
                 (λ (k v) (vector-set! vec k #t)))
  (check-equal? vec (vector #t #t #t)))

;; hamt->list
(check-equal? (sort (hamt->list fbb-hamt)
                    string<?
                    #:key cdr)
              '((bar . "bar") (baz . "baz") (foo . "foo")))

;; hamt-keys
(check-equal? (sort (hamt-keys fbb-hamt)
                    string<?
                    #:key symbol->string)
              '(bar baz foo))

;; hamt-values
(check-equal? (sort (hamt-values fbb-hamt) string<?)
              '("bar" "baz" "foo"))
                      
