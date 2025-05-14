(local say (require :say))

(fn same-in-arbitrary-order [_state [expected actual & _rest]]
  (if (or (not= "table" (type expected)) (not= "table" (type actual)))
      false
      (let [expected-includes-actual? (accumulate [same? nil k v (pairs expected)
                                                   &until (= false same?)]
                                        (and (= :number (type k)) ;
                                             (vim.list_contains actual v)))
            actual-includes-expected? (accumulate [same? nil k v (pairs actual)
                                                   &until (= false same?)]
                                        (and (= :number (type k)) ;
                                             (vim.list_contains expected v)))]
        (and (not= false expected-includes-actual?)
             (not= false actual-includes-expected?)))))

(say:set "assertion.same-in-arbitrary-order.positive" "Expected arrays to be the same in arbitrary order.
Passed in:
%s
Expected:
%s")

(say:set "assertion.same-in-arbitrary-order.negative" "Expected arrays to be different in arbitrary order.)
Passed in:
%s
Expected:
%s")

(assert:register "assertion" "same-in-arbitrary-order" same-in-arbitrary-order
                 "assertion.same-in-arbitrary-order.positive"
                 "assertion.same-in-arbitrary-order.negative")
