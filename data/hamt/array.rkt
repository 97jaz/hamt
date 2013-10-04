#lang racket/base

(provide array-length
         array-ref
         array
         array-replace
         array-insert
         array-remove)

(require racket/performance-hint)

(require racket/require
         (for-syntax racket/base)
         (filtered-in
          (λ (name) (regexp-replace #rx"unsafe-" name ""))
          racket/unsafe/ops))

(begin-encourage-inline
  (define array-length vector-length)
  (define array-ref vector*-ref)
  (define array vector)

  (define (array-replace arr idx val)
    (define len (vector-length arr))
    (define new (make-vector len))
    
    (let loop ([i 0])
      (cond [(fx= i idx)
             (vector*-set! new i val)
             (loop (fx+ i 1))]
            [(fx< i len)
             (vector*-set! new i (vector*-ref arr i))
             (loop (fx+ i 1))]
            [else
             new])))

  (define (array-insert arr idx val)
    (define new (make-vector (fx+ (vector-length arr) 1)))
    (vector-copy! new 0 arr 0 idx)
    (vector*-set! new idx val)
    (vector-copy! new (fx+ idx 1) arr idx)
    new)

  (define (array-remove arr idx)
    (define new (make-vector (fx- (vector-length arr) 1)))
    (vector-copy! new 0 arr 0 idx)
    (vector-copy! new idx arr (fx+ idx 1))
    new))