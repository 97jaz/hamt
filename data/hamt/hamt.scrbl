#lang scribble/doc

@(require scribble/manual
          (for-label racket/base
                     racket/contract
                     data/hamt))

@title{Immutable Hash Array Mapped Tries}
@author{@(author+email "Jon Zeppieri" "zeppieri@gmail.com")}
@bibliography[
@bib-entry[#:key "Bagwell2000"
           #:title "Ideal Hash Trees"
           #:author "Phil Bagwell"
           #:location "(Report). Infoscience Department, École Polytechnique Fédérale de Lausanne"
           #:date "2000"
           #:url "http://lampwww.epfl.ch/papers/idealhashtrees.pdf"]
]

@defmodule[data/hamt]

This package defines @deftech{immutable hash array mapped tries} (or @deftech{HAMT}s, for short).
An @tech{HAMT} is a @tech[#:doc '(lib "scribblings/reference/dicts.scrbl")]{dictionary}, and its
interface mimics that of an immutable @tech[#:doc '(lib "scribblings/reference/hashes.scrbl")]{hash table}.

Hash array mapped tries are described in @cite["Bagwell2000"].

@elemtag['(caveat "mutable-keys")]{@bold{Caveat concerning mutable
keys:}} If a key in an @racket[equal?]-based @tech{HAMT} is mutated
(e.g., a key string is modified with @racket[string-set!]), then the
@tech{HAMT}'s behavior for insertion, lookup, and remove operations
becomes unpredictable.

@(define (mutable-key-caveat)
  @elemref['(caveat "mutable-keys")]{caveat concerning mutable keys})

@(define (see-also-mutable-key-caveat)
   @t{See also the @mutable-key-caveat[] above.})

@defproc[(hamt? [v any/c]) boolean?]{
Returns @racket[#t] if @racket[v] is an @tech{HAMT}, @racket[#f] otherwise.
}

@deftogether[(
  @defproc[(hamt-equal? [hamt hamt?]) boolean?]
  @defproc[(hamt-eqv? [hamt hamt?]) boolean?]
  @defproc[(hamt-eq? [hamt hamt?]) boolean?]
)]{
@racket[hamt-equal?] returns @racket[#t] if the given @tech{HAMT}'s keys are compared with @racket[equal?], @racket[#f] otherwise.
@racket[hamt-eqv?] returns @racket[#t] if the given @tech{HAMT}'s keys are compared with @racket[eqv?], @racket[#f] otherwise.
@racket[hamt-eq?] returns @racket[#t] if the given @tech{HAMT}'s keys are compared with @racket[eq?], @racket[#f] otherwise.
}

@deftogether[(
  @defproc[(hamt [key any/c] [val any/c] ... ...) (and/c hamt? hamt-equal?)]
  @defproc[(hamteqv [key any/c] [val any/c] ... ...) (and/c hamt? hamt-eqv?)]
  @defproc[(hamteq [key any/c] [val any/c] ... ...) (and/c hamt? hamt-eq?)]
)]{
Creates an @tech{HAMT} with each @racket[key] mapped to the following @racket[val].
Each @racket[key] must have a @racket[val], so the total number of arguments must be even.

The @racket[hamt] procedure creates an @tech{HAMT} where keys are compared with @racket[equal?],
@racket[hamteqv] creates an @tech{HAMT} where keys are compared with @racket[eqv?], and
@racket[hamteq] creates an @tech{HAMT} where keys are compared with @racket[eq?].

The @racket[key] to @racket[val] mappings are added to the table in the order they appear in
the argument list, so later mappings can hide earlier ones if the @racket[key]s are equal.
}

@deftogether[(
   @defproc[(make-hamt [assocs (listof pair?) null]) (and/c hamt? hamt-equal?)]
   @defproc[(make-hamteqv [assocs (listof pair?) null]) (and/c hamt? hamt-eqv?)]
   @defproc[(make-hamteq [assocs (listof pair?) null]) (and/c hamt? hamt-eq?)]
)]{
Creates an @tech{HAMT} that is initialized with the contents of @racket[assocs]. In each element of
@racket[assocs], the @racket[car] is a key, and the @racket[cdr] is the corresponding value. The mappings 
are added to the table in the order they appear in the argument list, so later mappings can hide earlier
ones if the @racket[key]s are equal.

@racket[make-hamt] creates an @tech{HAMT} where the keys are compared with @racket[equal?],
@racket[make-hamteqv] creates an @tech{HAMT} where the keys are compared with @racket[eqv?], and
@racket[make-hamteq] creates an @tech{HAMT} where the keys are compared with @racket[eq?].
}

@defproc[(hamt-set [hamt hamt?] [key any/c] [v any/c]) hamt?]{
Functionally extends @racket[hamt] by mapping @racket[key] to @racket[v], overwriting any existing mapping
for @racket[key], and returning the extended @tech{HAMT}.

@see-also-mutable-key-caveat[]
}

@defproc[(hamt-set* [hamt hamt?] [key any/c] [v any/c] ... ...) hamt?]{
Functionally extends @racket[hamt] by mapping each @racket[key] to the following @racket[v], overwriting
any existing mapping for each @racket[key], and returning the extended @tech{HAMT}. Mappings are added to
the table in the order they appear in the argument list, so later mappings can hide earlier ones if the 
@racket[key]s are equal.
}

@defproc[(hamt-ref [hamt hamt?]
                   [key any/c]
                   [failure-result (λ ()
                                     (raise (exn:fail:contract ....)))])
         any/c]{
Returns the value for @racket[key] in @racket[hamt]. If no value is found for @racket[key], then
@racket[failure-result] determines the result:

@itemize[

 @item{If @racket[failure-result] is a procedure, it is called
       (through a tail call) with no arguments to produce the result.}

 @item{Otherwise, @racket[failure-result] is returned as the result.}

]

@see-also-mutable-key-caveat[]
}

@defproc[(hamt-has-key? [hamt hamt?] [key any/c]) boolean?]{
Returns @racket[#t] if @racket[hamt] contains a value for the given @racket[key], @racket[#f] otherwise.
}

@defproc[(hamt-remove [hamt hamt?] [key any/c]) hamt?]{
Functionally removes any existing mapping for @racket[key] in @racket[hamt], returning the fresh @tech{HAMT}.

@see-also-mutable-key-caveat[]
}

@defproc[(hamt-count [hamt hamt?]) exact-nonnegative-integer?]{
Returns the number of keys mapped by @racket[hamt].
}

@defproc[(hamt-empty? [hamt hamt?]) boolean?]{
Returns @racket[#t] just in case @racket[(zero? (hamt-count hamt))] is @racket[#t], @racket[#f] otherwise.
}

@defproc[(hamt-map [hamt hamt?] [proc (any/c any/c . -> . any/c)]) (listof any/c)]{
Applies the procedure @racket[proc] to each element of @racket[hamt] in an unspecified order,
accumulating the results into a list. The procedure @racket[proc] is called each time with a 
key and its value.
}

@defproc[(hamt-for-each [hamt hamt?] [proc (any/c any/c . -> . any/c)]) void?]{
Applies the procedure @racket[proc] to each element of @racket[hamt] (for the side-effects of
@racket[proc]) in an unspecified order. The procedure @racket[proc] is called each time with a 
key and its value.
}

@defproc[(hamt->list [hamt hamt?]) (listof (cons/c any/c any/c))]{
Returns a list of the key--value pairs of @racket[hamt] in an unspecified order.
}

@defproc[(hamt-keys [hamt hamt?]) (listof any/c)]{
Returns a list of the keys in @racket[hamt] in an unspecified order.
}

@defproc[(hamt-values [hamt hamt?]) (listof any/c)]{
Returns a list of the values in @racket[hamt] in an unspecified order.
}
