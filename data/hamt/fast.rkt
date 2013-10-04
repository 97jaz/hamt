#lang racket/base

(require racket/match
         racket/generator
         racket/dict
         "popcount.rkt"
         "array.rkt")

(require racket/require
         racket/performance-hint
         (for-syntax racket/base)
         (filtered-in
          (λ (name) (regexp-replace #rx"unsafe-" name ""))
          racket/unsafe/ops))

(provide hamt
         make-hamt
         hamteqv
         make-hamteqv
         hamteq
         make-hamteq
         hamt?
         hamt-equal?
         hamt-eqv?
         hamt-eq?
         hamt-count
         hamt-empty?
         hamt-has-key?
         hamt-ref
         hamt-set
         hamt-set*
         hamt-remove
         hamt-map
         hamt-keys
         hamt-values
         hamt->list
         hamt-for-each)


;; node types
(struct entry (key value) #:transparent)
(struct bnode (array bitmap) #:transparent)
(struct cnode (array hashcode) #:transparent)

;; iterator position
(struct hamt-position (hamt entry generator))

;; eta-expanded because the struct def needs to be below
(define (hamt? x) (HAMT? x))

(define (hamt-equal? x) (eq? (HAMT-name x) 'hamt))
(define (hamt-eqv? x)   (eq? (HAMT-name x) 'hamteqv))
(define (hamt-eq? x)    (eq? (HAMT-name x) 'hamteq))

(define (hamt-count h) (HAMT-count h))

(define-syntax-rule (define-hamt-constructors vararg-constructor list-constructor key= key#)
  (begin
    (define (vararg-constructor . kvs)
      (let loop ([kvs kvs] [h (HAMT 'vararg-constructor *empty-bnode* 0 key= key#)])
        (match kvs
          [(list-rest k v kvs) (loop kvs (hamt-set h k v))]
          [(list)              h]
          [(list k)            (raise (exn:fail:contract 
                                       (odd-kvlist-message 'vararg-constructor k)
                                       (current-continuation-marks)))])))

    (define (list-constructor [assocs '()])
      (for/fold ([h (vararg-constructor)]) ([pair (in-list assocs)])
        (hamt-set h (car pair) (cdr pair))))))

(define-hamt-constructors hamt make-hamt equal? equal-hash-code)
(define-hamt-constructors hamteqv make-hamteqv equal? eqv-hash-code)
(define-hamt-constructors hamteq make-hamteq equal? eq-hash-code)


(define (hamt-empty? h)
  (fx= (hamt-count h) 0))

(define (hamt-ref h key [default (λ ()
                                   (raise 
                                    (exn:fail:contract 
                                     (format "hamt-ref: no value found for key\n\tkey : ~s" key)
                                     (current-continuation-marks))))])
  (match h
    [(HAMT _ root _ key= key#)
     (node-ref root key (key# key) key= 0 default)]))

(define (hamt-has-key? h key)
  (not (nothing? (hamt-ref h key *nothing*))))

(define (hamt-set h key val)
  (match h
    [(HAMT name root count key= key#)
     (define-values (node added?) (node-set root key val (key# key) key= key# 0))
     
     (cond [(eq? node root) h]
           [else (let ([new-count (if added? (fx+ count 1) count)])
                   (HAMT name node new-count key= key#))])]))

(define (hamt-set* h . kvs)
  (let loop ([kvs kvs] [h h])
    (match kvs
      [(list-rest k v kvs) (loop kvs (hamt-set h k v))]
      [(list)              h]
      [(list k)            (raise (exn:fail:contract
                                   (odd-kvlist-message 'hamt-set* k)
                                   (current-continuation-marks)))])))


(define (hamt-remove h key)
  (match h
    [(HAMT name root count key= key#)
     (define node (node-remove root key (key# key) key= 0))
     
     (cond [(eq? node root) h]
           [else (HAMT name node (fx- count 1) key= key#)])]))

(define (hamt-map h proc)
  (hamt-fold h '() (λ (k v acc) (cons (proc k v) acc))))

(define (hamt-keys h)
  (hamt-fold h '() (λ (k _ acc) (cons k acc))))

(define (hamt-values h)
  (hamt-fold h '() (λ (_ v acc) (cons v acc))))

(define (hamt->list h)
  (hamt-fold h '() (λ (k v acc) (cons (cons k v) acc))))

(define (hamt-for-each h proc)
  (hamt-fold h (void) (λ (k v _) (void (proc k v)))))

(define (hamt-fold h id proc)
  (node-fold (HAMT-root h) id proc))

(define (hamt-iterate-first h)
  (if (zero? (hamt-count h))
      #f
      (let* ([g (generate-hamt-position h)]
             [x (g)])
        (and x (hamt-position h x g)))))

(define (hamt-iterate-next h pos)
  (match pos
    [(hamt-position h0 _ g)
     (cond [(eq? h h0)
            (let ([x (g)])
              (and x (hamt-position h x g)))]
           [else
            (raise (exn:fail:contract "invalid position" (current-continuation-marks)))])]))
     
(define (hamt-iterate-key h pos)
  (match pos
    [(hamt-position h0 (entry k _) _)
     (cond [(eq? h h0)
            k]
           [else
            (raise (exn:fail:contract "invalid position" (current-continuation-marks)))])]))

(define (hamt-iterate-value h pos)
  (match pos
    [(hamt-position h0 (entry _ v) _)
     (cond [(eq? h h0)
            v]
           [else
            (raise (exn:fail:contract "invalid position" (current-continuation-marks)))])]))

(define (hamt-write h port mode)
  (define recur (case mode
                  [(#t) write]
                  [(#f) display]
                  [else (λ (p port) (print p port mode))]))
  (write-string "#<" port)
  (write-string (symbol->string (HAMT-name h)) port)
  (recur (hamt->list h) port)
  (write-string ">" port))

(struct HAMT (name root count key= key#)
  #:methods gen:dict
  [(define dict-ref           hamt-ref)
   (define dict-set           hamt-set)
   (define dict-remove        hamt-remove)
   (define dict-count         hamt-count)
   (define dict-iterate-first hamt-iterate-first)
   (define dict-iterate-next  hamt-iterate-next)
   (define dict-iterate-key   hamt-iterate-key)
   (define dict-iterate-value hamt-iterate-value)]
  #:methods gen:custom-write
  [(define write-proc hamt-write)])
  

(define (node-ref node key keyhash key= shift default)
  (cond [(bnode? node) (bnode-ref node key keyhash key= shift default)]
        [(cnode? node) (cnode-ref node key keyhash key= shift default)]
        [else (error "[BUG] node-ref: unknown node type")]))

(define (node-set node key val keyhash key= key# shift)
  (cond [(bnode? node) (bnode-set node key val keyhash key= key# shift)]
        [(cnode? node) (cnode-set node key val keyhash key= key# shift)]
        [else (error "[BUG] node-set: unknown node type")]))

(define (node-remove node key keyhash key= shift)
  (cond [(bnode? node) (bnode-remove node key keyhash key= shift)]
        [(cnode? node) (cnode-remove node key keyhash key= shift)]
        [else (error "[BUG] node-remove: unknown node type")]))

(define (node-fold n acc proc)
  (match n
    [(bnode arr _) (array-fold arr acc proc)]
    [(cnode arr _) (array-fold arr acc proc)]
    [else (error "[BUG] node-fold: unknown node type")]))

(define (array-fold arr acc proc)
  (for*/fold ([acc acc]) ([i (in-range (array-length arr))]
                          [x (in-value (array-ref arr i))])
    (if (entry? x)
        (proc (entry-key x) (entry-value x) acc)
        (node-fold x acc proc))))

(define (bnode-ref node key keyhash key= shift default)
  (match (bnode-array-ref node keyhash shift)
    [(entry k v) (cond [(key= key k) v]
                       [else (return default)])]
    [#f          (return default)]
    [child       (node-ref child key keyhash key= (down shift) default)]))

(define (cnode-ref node key keyhash key= shift default)
  (match (cnode-array-ref node key keyhash key=)
    [(entry _ v) v]
    [_           (return default)]))

(define (bnode-set node key val keyhash key= key# shift)
  (match node
    [(bnode arr bitmap)
     (define bit (bnode-bit keyhash shift))
     (define idx (bnode-idx bitmap bit))
     
     (cond [(bit-set? bitmap bit)
            (match (array-ref arr idx)
              [(entry k v)
               (cond [(key= key k)
                      (values (bnode (array-replace arr idx (entry key val))
                                     bitmap)
                              #f)]
                     
                     [else
                      (define child (make-node k v key val keyhash key= key# (down shift)))
                      (values (bnode (array-replace arr idx child) bitmap)
                              #t)])]
              
              [child
               (define-values (new-child added?) (node-set child key val keyhash key= key# (down shift)))
               (values (bnode (array-replace arr idx new-child) bitmap)
                       added?)])]
           
           [else
            (values (bnode (array-insert arr idx (entry key val)) (bitwise-ior bitmap bit))
                    #t)])]))

(define (cnode-set node key val keyhash key= key# shift)
  (match node
    [(cnode arr hashcode)
     (cond [(= hashcode keyhash)
            (define idx (cnode-index arr key key=))
            
            (cond [idx (values (cnode (array-replace arr idx (entry key val)) hashcode)
                               #f)]
                  [else (values (cnode (array-insert arr (array-length arr) (entry key val)) hashcode)
                                #t)])]
           [else
            (let*-values ([(new)        (bnode (array node) (bnode-bit hashcode shift))]
                          [(new added?) (node-set new key val keyhash key= key# shift)])
              (values new added?))])]))

(define (bnode-remove node key keyhash key= shift)
  (match node
    [(bnode arr bitmap)
     (define bit (bnode-bit keyhash shift))
     (define idx (bnode-idx bitmap bit))
     
     (cond [(bit-set? bitmap bit)
            (match (array-ref arr idx)
              [(entry k _)
               (cond [(key= key k)
                      (define new-arr (array-remove arr idx))
                      
                      (cond [(contract-node? new-arr idx shift)
                             (array-ref new-arr 0)]
                            [else
                             (bnode new-arr (fxxor bitmap bit))])]
                     [else
                      node])]
              [child
               (define new-child (node-remove child key keyhash key= (down shift)))
               
               (cond [(eq? child new-child)
                      node]
                     [else
                      (bnode (array-replace arr idx new-child) bitmap)])])]
           [else
            node])]))

(define (cnode-remove node key keyhash key= shift)
  (match node
    [(cnode arr hashcode)
     (cond [(= hashcode keyhash)
            (define idx (cnode-index arr key key=))
            
            (cond [idx
                   (define new-arr (array-remove arr idx))
                   
                   (cond [(contract-node? new-arr idx shift)
                          (array-ref new-arr 0)]
                         [else
                          (cnode new-arr hashcode)])]
                  [else
                   node])]
           [else
            node])]))

(define (cnode-array-ref node key keyhash key=)
  (match node
    [(cnode arr hashcode)
     (and (= hashcode keyhash)
          (let ([i (cnode-index arr key key=)])
            (and i (array-ref arr i))))]))

(define (cnode-index arr key key=)
  (for*/first ([i (in-range (array-length arr))]
               [e (in-value (array-ref arr i))]
               #:when (key= key (entry-key e)))
            i))

(define (make-node k1 v1 k2 v2 k2hash key= key# shift)
  (define k1hash (key# k1))
  
  (cond [(= k1hash k2hash)
         (cnode (array (entry k1 v1) (entry k2 v2)) k1hash)]
        [else
         (let*-values ([(n _) (node-set *empty-bnode* k1 v1 k1hash key= key# shift)]
                       [(n _) (node-set n k2 v2 k2hash key= key# shift)])
           n)]))

(define (contract-node? arr idx shift)
  (and (fx= (array-length arr) 1)
       (fx> shift 0)
       (entry? (array-ref arr 0))))

(define (generate-hamt-position h)
  (generator () (hamt-fold h #f (λ (k v _) (yield (entry k v)) #f))))

(define (odd-kvlist-message name key)
  (format (string-append "~a: key does not have a value "
                         "(i.e., an odd number of arguments were provided)\n"
                         "\tkey: ~s")
          name
          key))

(begin-encourage-inline

  (define (bnode-array-ref node keyhash shift)
    (match node
      [(bnode arr bitmap)
       (define bit (bnode-bit keyhash shift))
     
       (cond [(bit-set? bitmap bit) 
              (define idx (bnode-idx bitmap bit))

              (array-ref arr idx)]
             [else
              #f])]))

  (define (bnode-bit keyhash shift)
    (fxlshift 1 
              (fxand (fxrshift keyhash shift) #x1f)))

  (define (bnode-idx bitmap bit)
    (popcount32 (fxand bitmap (fx- bit 1))))

  (define (bit-set? bitmap bit)
    (not (fx= 0 (fxand bitmap bit))))
  
  (define (down shift)
    (fx+ shift 4))

  (define (return default)
    (if (procedure? default)
        (default)
        default))
  
  (define (nothing? x) (eq? x *nothing*)))

(define *nothing* (list '*nothing*))
(define *empty-bnode* (bnode (array) 0))
