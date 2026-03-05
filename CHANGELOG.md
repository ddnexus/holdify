# CHANGELOG

## Version 1.3.4

- Fix RM run config
- Improve feedback making color_words_re HTML friendly

## Version 1.3.3

- Update gems
- Improve handling of diff yaml headers

## Version 1.3.2

- Change storage-key and feedback header
- Improve and normalize:
  - Mutex handling
  - User feedback
  - Method names
  - README
- Rename git > git_diff; wrap > dye
- Remove redundant parallel_executor setup and rubocop addition to the test task

## Version 1.3.1

- Improve the feedback for inspect; fixes the hunk length numbers

## Version 1.3.0

- Improvements and fixes:
  - Implement hold_dump that skips YAML anchor/alias notations for easy feedback
  - Improve failure feedback look and functionality
  - Add new minitest plugin options
  - Reorganize, normalize and optimize the code

## Version 1.2.0

- Update run configurations
- Add tests for the new features
- 💎 Improve usability:
  - Add failure headers linked to yaml file and test line
  - Add failure message and diff feedback, with direct colored word diff and line references
  - Remove pretty, now managed internally by Holdify.git and Holdify.color
- Fix non-core issues
- Update Gemfile

## Version 1.1.3

- Optimize performance:
  - Minimize IO operations
  - Use faster XXH3 hash algorithm
  - Improve handling of actual/expected values
  - Simplify code

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
