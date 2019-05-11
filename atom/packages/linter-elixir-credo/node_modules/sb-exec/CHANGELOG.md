## 2.0.5

- Remove `.flowconfig` from NPM package

## 2.0.4

- Fix a possible error where timeout would be passed to node
- Add support for non-string parameters ( Fixes #27 )

## 2.0.3

- Bump `consistent-env` version to include bugfixes

## 2.0.2

- Add `ignoreExitCode` option to ignore exit code when the stdout stream is empty

## 2.0.1

- Workaround several bugs on windows

## 2.0.0

- Add `exitCode` to return output when stream is `both`
- Throw if `stream` is `stderr` and there is no output, you can disable this by setting `allowEmptyStderr` option
- Throw if `stream` is `stdout` and exit code is non-zero

## 1.0.5

- Add fix for EXTPATH on windows

## 1.0.4

- Fix for Atom 1.7.0+ by setting env vars properly

## 1.0.3

- Fix a typo in Electron run as node var

## 1.0.2

- Add `local` option

## 1.0.1

- Make it work with `stdio: inherit`

## 1.0.0

- Initial release
