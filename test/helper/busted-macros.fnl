;; fennel-ls: macro-file

(macro when-not [pred ...]
  `(when (not ,pred)
     ,...))

(fn function? [x]
  "(Compile time) Check if `x` is anonymous function defined by builtin
constructor.
@param x any
@return boolean"
  (and (list? x) ;
       (case (. x 1 1)
         (where (or :fn :hashfn :lambda :partial :λ)) true)))

(fn ->fn [...]
  (if (or (sym? ...) (function? ...))
      (do
        ...)
      `#(do
          ,...)))

(λ inject-desc-fn [name desc ...]
  "Construct busted wrapper.
@param name string busted method name
@param desc string spec description
@param ... list a function, or any number of list to be wrapped into a function"
  (when-not (varg? desc)
    (assert (< 0 (select "#" ...)) "expected one or more args"))
  `(,name ,desc ,(->fn ...)))

(local describe* (partial inject-desc-fn `describe))
(local expose* (partial inject-desc-fn `expose))
(local insulate* (partial inject-desc-fn `insulate))
(local it* (partial inject-desc-fn `it))

{: describe* : expose* : insulate* : it*}
