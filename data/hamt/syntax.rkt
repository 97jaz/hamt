#lang racket/base

(require "fast.rkt"
         (for-syntax racket/base))

(provide (all-defined-out))

(define-syntax (for/hamt stx)
  (syntax-case stx ()
    [(_ clauses . defs+exprs)
     (with-syntax ([original stx])
       #'(for/fold/derived original ([h (hamt)]) clauses
                           (define-values (k v) (let () . defs+exprs))
                           (hamt-set h k v)))]))

(define-syntax (for*/hamt stx)
  (syntax-case stx ()
    [(_ clauses . defs+exprs)
     (with-syntax ([original stx])
       #'(for*/fold/derived original ([h (hamt)]) clauses
                            (define-values (k v) (let () . defs+exprs))
                            (hamt-set h k v)))]))

(define-syntax (for/hamteqv stx)
  (syntax-case stx ()
    [(_ clauses . defs+exprs)
     (with-syntax ([original stx])
       #'(for/fold/derived original ([h (hamteqv)]) clauses
                           (define-values (k v) (let () . defs+exprs))
                           (hamt-set h k v)))]))

(define-syntax (for*/hamteqv stx)
  (syntax-case stx ()
    [(_ clauses . defs+exprs)
     (with-syntax ([original stx])
       #'(for*/fold/derived original ([h (hamteqv)]) clauses
                            (define-values (k v) (let () . defs+exprs))
                            (hamt-set h k v)))]))

(define-syntax (for/hamteq stx)
  (syntax-case stx ()
    [(_ clauses . defs+exprs)
     (with-syntax ([original stx])
       #'(for/fold/derived original ([h (hamteq)]) clauses
                           (define-values (k v) (let () . defs+exprs))
                           (hamt-set h k v)))]))

(define-syntax (for*/hamteq stx)
  (syntax-case stx ()
    [(_ clauses . defs+exprs)
     (with-syntax ([original stx])
       #'(for*/fold/derived original ([h (hamteq)]) clauses
                            (define-values (k v) (let () . defs+exprs))
                            (hamt-set h k v)))]))
