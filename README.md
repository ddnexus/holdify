[![Gem Version](https://img.shields.io/gem/v/holdify.svg?label=holdify&colorA=99004d&colorB=cc0066)](https://rubygems.org/gems/holdify)
[![Build Status](https://img.shields.io/github/actions/workflow/status/ddnexus/holdify/holdify-ci.yml?branch=master)](https://github.com/ddnexus/holdify/actions/workflows/holdify-ci.yml?query=branch%3Amaster)</span> <span>
![Coverage](https://img.shields.io/badge/coverage-100%25-coverage.svg?colorA=1f7a1f&colorB=2aa22a)</span> <span>
![Rubocop Status](https://img.shields.io/badge/rubocop-passing-rubocop.svg?colorA=1f7a1f&colorB=2aa22a)</span> <span>
[![MIT license](https://img.shields.io/badge/license-MIT-mit.svg?colorA=1f7a1f&colorB=2aa22a)](http://opensource.org/licenses/MIT)

# Holdify

### Hardcoded values suck! Hold them inline!

Holdify eliminates the burden of maintaining large expected values into your test files. It behaves as if the expected value were hardcoded inline, but keeps it stored externally. This ensures your values hold true without polluting your test files, and allows for effortless updates when your code changes.

### Instead of this mess...

```ruby
it 'generates the pagination nav tag' do
  assert_equal("<nav id=" test - nav - id " class=" pagy - nav
  pagination " aria-label=" pager "><span class=" page prev "><a href=" / foo? page = 9 "  link-extra
  rel=" prev " aria-label=" previous ">&lsaquo;&nbsp;Prev</a></span> <span class=" page "><a
  href=" / foo? page = 1 "  link-extra >1</a></span> <span class=" page gap ">&hellip;</span>
  <span class=" page "><a href=" / foo? page = 6 "  link-extra >6</a></span> <span class=" page "><a
  href=" / foo? page = 7 "  link-extra >7</a></span> <span class=" page "><a href=" / foo? page = 8 "  link-extra
  >8</a></span> <span class=" page "><a href=" / foo? page = 9 "  link-extra rel=" prev " >9</a></span>
  <span class=" page active ">10</span> <span class=" page "><a href=" / foo? page = 11 "  link-extra
  rel=" next " >11</a></span> <span class=" page "><a href=" / foo? page = 12 "  link-extra
  >12</a></span> <span class=" page "><a href=" / foo? page = 13 "  link-extra >13</a></span>
  <span class=" page "><a href=" / foo? page = 14 "  link-extra >14</a></span> <span class=" page
  gap ">&hellip;</span> <span class=" page "><a href=" / foo? page = 50 "  link-extra >50</a></span>
  <span class=" page next "><a href=" / foo? page = 11 "  link-extra rel=" next " aria-label=" next ">Next&nbsp;&rsaquo;</a></span></nav>",
  view.pagy_nav(pagy))
end

it 'generates the metadata hash' do
  assert_equal(
  {
  :scaffold_url => "http://www.example.com/subdir?page=__pagy_page__",
  :first_url    => "http://www.example.com/subdir?page=1",
  :count        => 1000,
  :page         => 1,
  :items        => 20,
  # ... 40 more lines of hash data ...
  :series       => ["1", 2, 3, 4, 5, :gap, 50]
  },
  controller.pagy_metadata)
end
```

### Do it the _holdify_ way!

```ruby
it 'generates the pagination nav tag' do
  # Assertion
  assert_hold view.pagy_nav(pagy)
  
  # Expectation (standard)
  _(view.pagy_nav(pagy)).must_hold
  
  # Expectation (fluent / RSpec-style)
  expect(view.pagy_nav(pagy)).to_hold
  value(view.pagy_nav(pagy)).must_hold
end
```

## Why Holdify?

Most snapshot libraries bind stored values to the test name. If you rename a test, your snapshots break or become orphaned.
Holdify is different. It holds them inline.

- Bound to Code, Not Names: Holdify binds values to the line number of the assertion. You can rename your test methods or describe blocks freely without breaking your snapshots.
- One-to-One Feedback: The YAML store mirrors your file structure. An assertion at line 10 in your code corresponds exactly to L10 in the store file. No guessing which snapshot belongs to which test.
- Surgical Precision:
    - Need to update just one value? Add a ! (e.g., assert_hold!).
    - Need to see what's being generated without changing anything? Add a _? (e.g., assert_hold_?).
    - No need to regenerate the entire suite or fiddle with global environment variables.
- Resilient: Even if you move code around, Holdify's smart indexing (based on line content hashing) keeps track of your values, automatically updating line numbers in the store on the next run.

## Installation

Add `holdify` to your `Gemfile` (usually in the `:test` group).
Minitest < 6.0 loads it automatically. For Minitest >= 6.0, add `Minitest.load :holdify` to your `test_helper.rb`.

## How it works

Holdify binds the stored value to the **exact line number** of your assertion.

1.  **Capture:** The first time a test runs, Holdify captures the returned value and stores it in a `*.yaml` file next to the test.
2.  **Bind:** The value is indexed by the line number (e.g., `L10`), creating a virtual link between your code and the stored data.
3.  **Assert:** On subsequent runs, Holdify checks that the fresh value matches the one "held" at that line.

> [!TIP]
> **Mental Model:** Imagine the expected value is written directly in your test file at line X. Holdify simply moves that text into a separate file (indexed by `LX`) to keep your code clean, but the assertion remains strictly bound to that specific line, You can even inspect the YAML file for a one-to-one feedback.

### Updating stored values

When your code changes intentionally, you need to tell Holdify to accept the new reality. You have three options:

1.  **Rebuild all:** Run tests with the `--holdify-rebuild` option.
    ```sh
    rake test TESTOPTS=--holdify-rebuild
    ```
    > [!WARNING]
    > Only use this when you are sure *all* new outputs are correct: everything will be overwritten!

2.  **Manual deletion:** Delete the specific `*.yaml` store file and re-run the test. Ideally suited for when you want to reset a specific test file.

3.  **Selective update (The "Bang" method):** Temporarily replace the method with its `!` counterpart. This forces Holdify to update the store for that specific assertion.
  - `assert_hold` &rarr; `assert_hold!`
  - `must_hold` &rarr; `must_hold!`
  - `to_hold` &rarr; `to_hold!`

    > [!WARNING]
    > This stores the new value immediately but **raises an error** intentionally. This ensures you don't accidentally commit the `!` method. Revert to the standard method to pass the test.

### Inspecting Values

To quickly inspect the YAML output of a value without modifying the store, append `_?` to the method name (e.g., `assert_hold_?`, `must_hold_?`). This prints the value to `stderr` before running the standard assertion.

> [!NOTE]
> While `?` conventionally denotes a boolean predicate, Holdify uses it here as a **query** ("What is this value?"). It is designed as a temporary debugging tool.

### Assertions and Expectations

By default, Holdify wraps `assert_equal` _(or `assert_nil`, depending on the value)_. You can also specify a different equality assertion (e.g., `assert_equal_unordered`).

```ruby
# Standard usage
assert_hold actual
_(actual).must_hold

# With custom assertion logic
assert_hold actual, :assert_equal_unordered
_(actual).must_hold :assert_equal_unordered
expect(actual).to_hold :assert_equal_unordered

# With custom failure message
assert_hold actual, 'Data consistency failed'
_(actual).must_hold 'Data consistency failed'
```

**Note:** The custom assertion must be a symbol (e.g., `:assert_something`) not an expectation (e.g, `:must_something`). The order of arguments (assertion symbol vs message) is flexible.

### Store Format

Holdify stores values in a standard YAML file named after your test file (e.g., `test_file.rb.yaml`). The keys are designed to be human-readable, allowing you to easily correlate stored values with your source code:

- **Line Matching:** Keys start with `L<num>` corresponding to the line number of the assertion in your test file (e.g., `L10`).
- **Multiple Hits:** If a single assertion line is executed multiple times (e.g., inside a loop), Holdify stores them as a chronological list under the same key.

**Example:**

```yaml
---
# Simple assertion at line 10
L10 8a93...:
- "simple value"

# Loop executing line 15 twice
L15 2b4c...:
- "iteration 1"
- "iteration 2"
```

### Labeling Values

You can add context to your stored values by wrapping them in a Hash. This makes the YAML store self-documenting.

```ruby
it 'checks permissions' do
  # Pass a hash with a meaningful key
  expect(permissions: user.permissions).to_hold
end
```

The store file will look like this:

```yaml
L10 8a93...:
- :permissions: 
  - :read
  - :write
```

## Caveats

*   **Equality:** Stored values are verified using standard Minitest assertions. Custom objects must implement `==` correctly to be held.
*   **YAML serialization:** Complex objects with `ivars` might serialize differently across Ruby versions due to `Psych` (YAML) changes. It is safer to store raw data (hashes/attributes) to avoid this.

## Repository Info

### Versioning

Follows [Semantic Versioning 2.0.0](https://semver.org/). See the [Changelog](https://github.com/ddnexus/holdify/blob/master/CHANGELOG.md).

### Contributions

Pull Requests are welcome! Ensure tests, Codecov, and Rubocop pass.

### Branches

*   `master`: Latest published release. Never force-pushed.
*   `dev`: Development branch. May be force-pushed.

## License

[MIT License](https://opensource.org/licenses/MIT).
