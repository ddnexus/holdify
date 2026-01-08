# CHANGELOG

## Version 1.1.2

- Refactor store files:
  - Replace sha1 hash with xxHash
  - Add test/store/updates generator

## Version 1.1.1

- Improve and simplify internal structure and class interactions

## Version 1.1.0

- Fix edge cases for twin lines in the same file
- Implement pretty failure diffs
- Update to ruby 4.0.0

## Version 1.0.3

- Refactor test:
  - Reorganize the structure
  - Improve coverage
  - Comply with rubocop
- Refactor and fix lib:
  - Holdify is a module
  - Simplify find_location
  - Simplify and improve holdify_plugin.rb

## Version 1.0.2

- Rename rebuild > reconcile; improve README.md

## Version 1.0.1

- Improve description for rubygems.org
- Prefix the gem name with "minitest-"

## Version 1.0.0

Initial implementation
