(local Config (require :thyme.config))

(local M {})

(fn M.enable-dropin-paren! []
  "Activate nvim-dropin integration."
  (when Config.integration.dropin
    (let [dropin (require :dropin)]
      (dropin.pattern "^(.-)[fF][nN][lL]?(.*)" "%1Fnl%2")
      (dropin.pattern "^(.-)([[%[%(%{].*)" "%1Fnl %2"))))

M
