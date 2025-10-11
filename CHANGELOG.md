# Changelog

## [1.5.0](https://github.com/aileot/nvim-thyme/compare/v1.4.0...v1.5.0) (2025-10-11)


### Features

* **command:** (experimental) support range for `:Fnl` ([#74](https://github.com/aileot/nvim-thyme/issues/74)) ([0c158e1](https://github.com/aileot/nvim-thyme/commit/0c158e18960f4191144dce13599c4a9a7c8f99f5))
* **command:** add `:ThymeConfigRecommend` ([#83](https://github.com/aileot/nvim-thyme/issues/83)) ([77239eb](https://github.com/aileot/nvim-thyme/commit/77239eb102556ead2be1c26534aeee6c9f6fa744))
* **dropin:** extend pattern for case-insensitive `:Fnl` ([#86](https://github.com/aileot/nvim-thyme/issues/86)) ([ee27f3f](https://github.com/aileot/nvim-thyme/commit/ee27f3f77b4afd2064d31f7036e0cd056ad2322c))


### Bug Fixes

* **command:** do not try to edit cmd history with `ignore` method ([#79](https://github.com/aileot/nvim-thyme/issues/79)) ([39acc34](https://github.com/aileot/nvim-thyme/commit/39acc349fb2b4414e23123d1e95d34f0af542050))
* **dropin:** extend pattern considering cmd mods ([#81](https://github.com/aileot/nvim-thyme/issues/81)) ([d49fa18](https://github.com/aileot/nvim-thyme/commit/d49fa18fbf42b0b767422c012c2fe8cf8ca193e6))

## [1.4.0](https://github.com/aileot/nvim-thyme/compare/v1.3.0...v1.4.0) (2025-06-08)


### Features

* **dropin:** extend to cmdwin ([#67](https://github.com/aileot/nvim-thyme/issues/67)) ([d832ddf](https://github.com/aileot/nvim-thyme/commit/d832ddfe9b6cd24803157ac90cc7c1a2d552571a))


### Bug Fixes

* **command:** display `nil` result ([#72](https://github.com/aileot/nvim-thyme/issues/72)) ([9b75c15](https://github.com/aileot/nvim-thyme/commit/9b75c153e73ceaf3c56d87b1b5f6a8e33af7c33b))
* **keymap:** correctly show results that depend on `fennel.view` ([#70](https://github.com/aileot/nvim-thyme/issues/70)) ([2f2f9bc](https://github.com/aileot/nvim-thyme/commit/2f2f9bce0a2a6599b1b4452e25c831278808f84c))
* **treesitter:** truncate trailing whitespace chunks ([#69](https://github.com/aileot/nvim-thyme/issues/69)) ([052dc48](https://github.com/aileot/nvim-thyme/commit/052dc482ba393c2793eecade836c8894b76008cc))

## [1.3.0](https://github.com/aileot/nvim-thyme/compare/v1.2.0...v1.3.0) (2025-06-07)


### Features

* **dropin:** extract `nextcmd` recursively ([#62](https://github.com/aileot/nvim-thyme/issues/62)) ([9a8947c](https://github.com/aileot/nvim-thyme/commit/9a8947cf40330c70dc750b5e48f3d31b83bd54b9))
* **health:** report imported macros ([#54](https://github.com/aileot/nvim-thyme/issues/54)) ([46228a2](https://github.com/aileot/nvim-thyme/commit/46228a267bb26f7ad8bb921745654eb92e35a57b)), closes [#27](https://github.com/aileot/nvim-thyme/issues/27)
* **health:** report mounted-paths ([#57](https://github.com/aileot/nvim-thyme/issues/57)) ([f62b1fb](https://github.com/aileot/nvim-thyme/commit/f62b1fb344236497c64f26663467b9db0bab7fd3))
* **query:** inject "fennel" highlights in Cmdline on extui ([#60](https://github.com/aileot/nvim-thyme/issues/60)) ([aa87848](https://github.com/aileot/nvim-thyme/commit/aa87848f22eefa40bc4a9b4221ee95699561c6c0))


### Bug Fixes

* **treesitter:** truncate trailing whitespace chunks ([#61](https://github.com/aileot/nvim-thyme/issues/61)) ([2dfa9b6](https://github.com/aileot/nvim-thyme/commit/2dfa9b6a6015dedc956a7098c675724aaacf1ce0))

## [1.2.0](https://github.com/aileot/nvim-thyme/compare/v1.1.0...v1.2.0) (2025-06-02)


### Features

* **config:** add option `disable-treesitter-highlights` ([#52](https://github.com/aileot/nvim-thyme/issues/52)) ([6423714](https://github.com/aileot/nvim-thyme/commit/64237145742e2f5e689ad4dd9b356bd61945c0a9))


### Bug Fixes

* **config:** allow option values to be `false` ([#50](https://github.com/aileot/nvim-thyme/issues/50)) ([e78845f](https://github.com/aileot/nvim-thyme/commit/e78845f7b3abd0d6eb67a11eda093d05a6ae2cb2))
* **util:** let recursive file detection apart from `vim.fs.dir` ([#53](https://github.com/aileot/nvim-thyme/issues/53)) ([74ed9d8](https://github.com/aileot/nvim-thyme/commit/74ed9d86d70c1b11475bd4a3b136458b82ac6f95))

## [1.1.0](https://github.com/aileot/nvim-thyme/compare/v1.0.3...v1.1.0) (2025-05-31)


### Features

* **command:** add `:FnlBufCompile` and `:FnlFileCompile` as aliases ([#17](https://github.com/aileot/nvim-thyme/issues/17)) ([35a6293](https://github.com/aileot/nvim-thyme/commit/35a62932dd4c7391e59aeef46f4e7ef96469f9a4))
* **example:** add `snacks.notifier` to fallback notifier ([#43](https://github.com/aileot/nvim-thyme/issues/43)) ([f8438f5](https://github.com/aileot/nvim-thyme/commit/f8438f5b05764238d3188cb09a4df3f3d77d8318))


### Bug Fixes

* **command:** fix `:FnlFileCompile` just to print compiled results ([#44](https://github.com/aileot/nvim-thyme/issues/44)) ([2ec08a6](https://github.com/aileot/nvim-thyme/commit/2ec08a6b5c290753d300eeb63c288dd695295856))

## [1.0.3](https://github.com/aileot/nvim-thyme/compare/v1.0.2...v1.0.3) (2025-05-30)


### Bug Fixes

* **config:** remove default `keymap.mappings` ([#31](https://github.com/aileot/nvim-thyme/issues/31)) ([36c8cd7](https://github.com/aileot/nvim-thyme/commit/36c8cd72f7bffed7a1827e7cfb4f28fb667f8a27)), closes [#29](https://github.com/aileot/nvim-thyme/issues/29)
* **example:** comment out duplicated `keymap.mappings` value ([#35](https://github.com/aileot/nvim-thyme/issues/35)) ([a41d84a](https://github.com/aileot/nvim-thyme/commit/a41d84af4be8337d2b604de645edf81ee7e7788a))
* **health:** disable broken health check ([#28](https://github.com/aileot/nvim-thyme/issues/28)) ([0f2cdc9](https://github.com/aileot/nvim-thyme/commit/0f2cdc9d466f9b7b2529e2477b0b08a6c22ae5b6))

## [1.0.2](https://github.com/aileot/nvim-thyme/compare/v1.0.1...v1.0.2) (2025-05-29)


### Bug Fixes

* **config:** insert missing `lua/?/init-macros.fnl` at `stdpath("config")` for default/example config ([#19](https://github.com/aileot/nvim-thyme/issues/19)) ([6bd46b7](https://github.com/aileot/nvim-thyme/commit/6bd46b74927192e2772758f1270674224d491cc8))
* **loader:** make sure failure messages start with "\n" ([#9](https://github.com/aileot/nvim-thyme/issues/9)) ([a6d3a2e](https://github.com/aileot/nvim-thyme/commit/a6d3a2e9ef2717be2651f190f057859ce47a3b05))
* **treesitter:** make sure to set priority in number ([#16](https://github.com/aileot/nvim-thyme/issues/16)) ([873da95](https://github.com/aileot/nvim-thyme/commit/873da950d6cb53f317efa1dc531b611065323e06))
* **treesitter:** reduce "Press ENTER" message for oneline output  ([#20](https://github.com/aileot/nvim-thyme/issues/20)) ([76bc545](https://github.com/aileot/nvim-thyme/commit/76bc54563d49ff7bdf470409fce746a10c97fa12))

## [1.0.1](https://github.com/aileot/nvim-thyme/compare/v1.0.0...v1.0.1) (2025-05-24)


### Bug Fixes

* **watch:** deal with loaded file buffer later removed externally ([#6](https://github.com/aileot/nvim-thyme/issues/6)) ([fa6aa7b](https://github.com/aileot/nvim-thyme/commit/fa6aa7b90f8b80fbef77acda3f839d82b754300d))

## 1.0.0 (2025-05-24)

Initial Release
