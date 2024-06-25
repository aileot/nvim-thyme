(local {: lua-cache-prefix} (require :thyme.const))

(fn remove-context-files! []
  ;; NOTE: Leave fennel repo in cache to avoid redundant `git-clone`s.
  (vim.fn.delete lua-cache-prefix :rf)
  (vim.fn.delete (vim.fn.stdpath :data) :rf)
  (vim.fn.delete (vim.fn.stdpath :state) :rf))

{: remove-context-files!}
