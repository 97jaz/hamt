#lang racket/base

(require racket/require
         (for-syntax racket/base)
         (filtered-in
          (λ (name) (regexp-replace #rx"unsafe-" name ""))
          racket/unsafe/ops))

(require (only-in rnrs/arithmetic/bitwise-6 bitwise-bit-count)
         racket/performance-hint)

(provide popcount32)

(define-inline (popcount32 n)
  (fx+ (vector*-ref wordbits (fxand n #xffff))
       (vector*-ref wordbits (fxrshift n 16))))

(define wordbits
  (for/vector ([i (in-range 65536)])
    (bitwise-bit-count i)))

