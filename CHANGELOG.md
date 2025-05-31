# Changelog

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
