#lang racket/base

(require racket/contract/base
         "hamt/fast.rkt"
         "hamt/syntax.rkt")

(provide for/hamt for*/hamt
         for/hamteqv for*/hamteqv
         for/hamteq for*/hamteq)

(provide/contract
 [hamt            (() #:rest (listof any/c) . ->* . (and/c hamt? hamt-equal?))]
 [hamteqv         (() #:rest (listof any/c) . ->* . (and/c hamt? hamt-eqv?))]
 [hamteq          (() #:rest (listof any/c) . ->* . (and/c hamt? hamt-eq?))]
 [make-hamt       (() ((listof (cons/c any/c any/c))) . ->* . (and/c hamt? hamt-equal?))]
 [make-hamteqv    (() ((listof (cons/c any/c any/c))) . ->* . (and/c hamt? hamt-eqv?))]
 [make-hamteq     (() ((listof (cons/c any/c any/c))) . ->* . (and/c hamt? hamt-eq?))]
 [hamt?           (any/c . -> . boolean?)]
 [hamt-equal?     (hamt? . -> . boolean?)]
 [hamt-eqv?       (hamt? . -> . boolean?)]
 [hamt-eq?        (hamt? . -> . boolean?)]
 [hamt-count      (hamt? . -> . exact-nonnegative-integer?)]
 [hamt-empty?     (hamt? . -> . boolean?)]
 [hamt-has-key?   (hamt? any/c . -> . boolean?)]
 [hamt-has-value? ((hamt? any/c) ((any/c any/c . -> . boolean?)) . ->* . boolean?)]
 [hamt-ref        ((hamt? any/c) (any/c) . ->* . any/c)]
 [hamt-set        (hamt? any/c any/c . -> . hamt?)]
 [hamt-set*       ((hamt?) #:rest (listof any/c) . ->* . hamt?)]
 [hamt-remove     (hamt? any/c . -> . hamt?)]
 [hamt-map        (hamt? (any/c any/c . -> . any/c) . -> . (listof any/c))]
 [hamt-for-each   (hamt? (any/c any/c . -> . any/c) . -> . void?)]
 [hamt->list      (hamt? . -> . (listof (cons/c any/c any/c)))]
 [hamt-keys       (hamt? . -> . (listof any/c))]
 [hamt-values     (hamt? . -> . (listof any/c))])
