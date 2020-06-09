# ochangelog

Automize your changelog manipulation when releasing in the following two ways:\n\
- get a suggestion for what the next version number should be; make use of that, for example, in a script\n\
- bump your changelog by using a `dune alias` with a `diff` action attached and calling `dune promote`. See _Example_ for that.

## Installation

```
opam pin add --yes https://github.com/pitag-ha/ochangelog.git
opam install ochangelog
```

If you want to contribute to the project, please read
[CONTRIBUTING.md](CONTRIBUTING.md).

## Example

You can include the following into your `dune` file (where `CHANGE.md` should be replaced by the path to your changelog, if it's different):
```
(alias
 (name changelog-bump))

(rule
 (alias changelog-bump)
 (action
  (with-stdout-to
   changelog.gen
   (run ochangelog changelog-bump "CHANGE.md"))))

(rule
 (alias changelog-bump)
 (action
  (diff CHANGE.md changelog.gen)))
```

Then, whenever you run `dune build @changelog-bump`, ochangelog figures out what kind of semantic change your new release should be tagged as and updates the changelog accordingly. You can see the diff between your changelog and the updated changelog on your terminal. If you're happy with it, run `dune promote` to actually update your changelog.

For example, suppose your changelog looks as follows:
```
## unreleased

### Added

- added something nice

### Security

- digged some security hole

### Fixed

### Changed

## 12.14.2 (8-3-2019)

(...)
```

Then, if you run `dune build @changelog-bump` and then `dune promote` (and we suppose today is 2020-6-8), it will be bumped to:
```
## unreleased

### Added

### Changed

### Deprecated

### Fixed

### Removed

### Security

## 12.15.0 (2020-6-8)

### Added

- added something nice

### Security

- digged some security hole

### Fixed

### Changed

## 12.14.2 (8-3-2019)

(...)
```
