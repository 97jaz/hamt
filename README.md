Immutable Hash Array Mapped Tries

Jon Zeppieri <[zeppieri@gmail.com](mailto:zeppieri@gmail.com)>

```racket
 (require data/hamt)
```

This package defines _immutable hash array mapped tries_ (or _HAMT_s,
for short). An HAMT is a dictionary, and its interface mimics that of an
immutable hash table.

Hash array mapped tries are described in [Bagwell2000].

**Caveat concerning mutable keys:** If a key in an `equal?`-based HAMT
is mutated (e.g., a key string is modified with `string-set!`), then the
HAMT’s behavior for insertion, lookup, and remove operations becomes
unpredictable.

```racket
(hamt? v) -> boolean?
  v : any/c          
```

Returns `#t` if `v` is an HAMT, `#f` otherwise.

```racket
(hamt-equal? hamt) -> boolean?
  hamt : hamt?                
(hamt-eqv? hamt) -> boolean?  
  hamt : hamt?                
(hamt-eq? hamt) -> boolean?   
  hamt : hamt?                
```

`hamt-equal?` returns `#t` if the given HAMT’s keys are compared with
`equal?`, `#f` otherwise. `hamt-eqv?` returns `#t` if the given HAMT’s
keys are compared with `eqv?`, `#f` otherwise. `hamt-eq?` returns `#t`
if the given HAMT’s keys are compared with `eq?`, `#f` otherwise.

```racket
(hamt key val ... ...) -> (and/c hamt? hamt-equal?) 
  key : any/c                                       
  val : any/c                                       
(hamteqv key val ... ...) -> (and/c hamt? hamt-eqv?)
  key : any/c                                       
  val : any/c                                       
(hamteq key val ... ...) -> (and/c hamt? hamt-eq?)  
  key : any/c                                       
  val : any/c                                       
```

Creates an HAMT with each `key` mapped to the following `val`. Each
`key` must have a `val`, so the total number of arguments must be even.

The `hamt` procedure creates an HAMT where keys are compared with
`equal?`, `hamteqv` creates an HAMT where keys are compared with `eqv?`,
and `hamteq` creates an HAMT where keys are compared with `eq?`.

The `key` to `val` mappings are added to the table in the order they
appear in the argument list, so later mappings can hide earlier ones if
the `key`s are equal.

```racket
(make-hamt [assocs]) -> (and/c hamt? hamt-equal?) 
  assocs : (listof pair?) = null                  
(make-hamteqv [assocs]) -> (and/c hamt? hamt-eqv?)
  assocs : (listof pair?) = null                  
(make-hamteq [assocs]) -> (and/c hamt? hamt-eq?)  
  assocs : (listof pair?) = null                  
```

Creates an HAMT that is initialized with the contents of `assocs`. In
each element of `assocs`, the `car` is a key, and the `cdr` is the
corresponding value. The mappings are added to the table in the order
they appear in the argument list, so later mappings can hide earlier
ones if the `key`s are equal.

`make-hamt` creates an HAMT where the keys are compared with `equal?`,
`make-hamteqv` creates an HAMT where the keys are compared with `eqv?`,
and `make-hamteq` creates an HAMT where the keys are compared with
`eq?`.

```racket
(hamt-set hamt key v) -> hamt?
  hamt : hamt?                
  key : any/c                 
  v : any/c                   
```

Functionally extends `hamt` by mapping `key` to `v`, overwriting any
existing mapping for `key`, and returning the extended HAMT.

See also the caveat concerning mutable keys above.

```racket
(hamt-set* hamt key v ... ...) -> hamt?
  hamt : hamt?                         
  key : any/c                          
  v : any/c                            
```

Functionally extends `hamt` by mapping each `key` to the following `v`,
overwriting any existing mapping for each `key`, and returning the
extended HAMT. Mappings are added to the table in the order they appear
in the argument list, so later mappings can hide earlier ones if the
`key`s are equal.

```racket
(hamt-ref hamt key failure-result) -> any/c           
  hamt : hamt?                                        
  key : any/c                                         
  failure-result : (λ ()                              
                     (raise (exn:fail:contract ....)))
```

Returns the value for `key` in `hamt`. If no value is found for `key`,
then `failure-result` determines the result:

* If `failure-result` is a procedure, it is called (through a tail call)
  with no arguments to produce the result.

* Otherwise, `failure-result` is returned as the result.

See also the caveat concerning mutable keys above.

```racket
(hamt-has-key? hamt key) -> boolean?
  hamt : hamt?                      
  key : any/c                       
```

Returns `#t` if `hamt` contains a value for the given `key`, `#f`
otherwise.

```racket
(hamt-remove hamt key) -> hamt?
  hamt : hamt?                 
  key : any/c                  
```

Functionally removes any existing mapping for `key` in `hamt`, returning
the fresh HAMT.

See also the caveat concerning mutable keys above.

```racket
(hamt-count hamt) -> exact-nonnegative-integer?
  hamt : hamt?                                 
```

Returns the number of keys mapped by `hamt`.

```racket
(hamt-empty? hamt) -> boolean?
  hamt : hamt?                
```

Returns `#t` just in case `(zero? (hamt-count hamt))` is `#t`, `#f`
otherwise.

```racket
(hamt-map hamt proc) -> (listof any/c)
  hamt : hamt?                        
  proc : (any/c any/c . -> . any/c)   
```

Applies the procedure `proc` to each element of `hamt` in an unspecified
order, accumulating the results into a list. The procedure `proc` is
called each time with a key and its value.

```racket
(hamt-for-each hamt proc) -> void? 
  hamt : hamt?                     
  proc : (any/c any/c . -> . any/c)
```

Applies the procedure `proc` to each element of `hamt` (for the
side-effects of `proc`) in an unspecified order. The procedure `proc` is
called each time with a key and its value.

```racket
(hamt->list hamt) -> (listof (cons/c any/c any/c))
  hamt : hamt?                                    
```

Returns a list of the key–value pairs of `hamt` in an unspecified order.

```racket
(hamt-keys hamt) -> (listof any/c)
  hamt : hamt?                    
```

Returns a list of the keys in `hamt` in an unspecified order.

```racket
(hamt-values hamt) -> (listof any/c)
  hamt : hamt?                      
```

Returns a list of the values in `hamt` in an unspecified order.

# Bibliography

[Bagwell2000] Phil Bagwell, “Ideal Hash Trees,” (Report). Infoscience Department,
              École Polytechnique Fédérale de Lausanne, 2000.                    
              `http://lampwww.epfl.ch/papers/idealhashtrees.pdf`                 
