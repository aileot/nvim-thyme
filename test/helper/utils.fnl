(fn remove-context-files! []
  ;; NOTE: Indiscriminately removing stdpath/data results in too many attempts
  ;; to re-download the online test deps like fennel, parinfer, etc.
  (let [cache-dirs [:cache :data :state]]
    (each [_ dir (ipairs cache-dirs)]
      (-> (vim.fn.stdpath dir)
          (vim.fs.joinpath :thyme)
          (vim.fn.delete :rf)))))

{: remove-context-files!}
