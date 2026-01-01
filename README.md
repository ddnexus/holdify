[![Gem Version](https://img.shields.io/gem/v/minitest-holdify.svg?label=holdify&colorA=99004d&colorB=cc0066)](https://rubygems.org/gems/minitest-holdify)
[![Build Status](https://img.shields.io/github/actions/workflow/status/ddnexus/holdify/holdify-ci.yml?branch=master)](https://github.com/ddnexus/holdify/actions/workflows/holdify-ci.yml?query=branch%3Amaster)</span> <span>
![Coverage](https://img.shields.io/badge/coverage-100%25-coverage.svg?colorA=1f7a1f&colorB=2aa22a)</span> <span>
![Rubocop Status](https://img.shields.io/badge/rubocop-passing-rubocop.svg?colorA=1f7a1f&colorB=2aa22a)</span> <span>
[![MIT license](https://img.shields.io/badge/license-MIT-mit.svg?colorA=1f7a1f&colorB=2aa22a)](http://opensource.org/licenses/MIT)

# Holdify

### Hardcoded values suck! Holdify them.

Stop maintaining large expected values in your test/fixture files! Hold them automatically. Update them effortlessly.

### Instead of this mess...

```ruby
it 'generates the series_nav' do
  assert_equal("<nav class=\"pagy series-nav\" aria-label=\"Pages\"><a role=\"link\" aria-disabled=\"true\"
 aria-label=\"Previous\">&lt;</a><a role=\"link\" aria-disabled=\"true\" aria-current=\"page\">1</a><a 
href=\"/path?example=123&page=2\" rel=\"next\">2</a><a href=\"/path?example=123&page=3\">3</a><a href=\"/path?
example=123&page=4\">4</a><a href=\"/path?example=123&page=5\">5</a><a href=\"/path?example=123&page=6\">
6</a><a href=\"/path?example=123&page=7\">7</a><a href=\"/path?example=123&page=8\">8</a><a href=\"/path?
example=123&page=9\">9</a><a role=\"separator\" aria-disabled=\"true\">&hellip;</a><a href=\"/path?
example=123&page=50\">50</a><a href=\"/path?example=123&page=2\" rel=\"next\" aria-label=\"Next\">&gt;</a></nav>",
  @pagy.series_nav)
end

it 'generates the data_hash' do
  assert_equal({ url_template: "/path?example=123&page=P ", first_url: "/path?example=123", 
    current_url: "/path?example=123&page=1", page_url: "/path?example=123&page=1", 
    next_url: "/path?example=123&page=2", last_url: "/path?example=123&page=50", count: 1000, page: 1, 
    limit: 20, last: 50, in: 20, from: 1, to: 20, next: 2, options: { limit: 20, limit_key: "limit",
    page_key: "page", page: 1, count: 1000 } }, @pagy.data_hash)
end
```

### Holdify your tests!

Write the same as:

```ruby
it 'generates the series_nav' do
  assert_hold @pagy.series_nav
end

it 'generates the data_hash' do
  assert_hold @pagy.data_hash
end
```

Or if you prefer a more expressive syntax:

```ruby
it 'generates the series_nav' do
  expect(@pagy.series_nav).to_hold
end

it 'generates the data_hash' do
  expect(@pagy.data_hash).to_hold
end
```

> [!NOTE]
> Of course you can also use the `_()` or `value()` with `must_hold`.
> For example: `value(anything).must_hold`

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

Add `minitest-holdify` to your `Gemfile` (usually in the `:test` group).
Minitest < 6.0 loads it automatically. For Minitest >= 6.0, add `Minitest.load :holdify` to your `test_helper.rb`.

## How it works

Holdify binds the stored value to the **exact line number** of your assertion.

1.  **Capture:** The first time a test runs, Holdify captures the returned value and stores it in a `*.yaml` file next to the test.
2.  **Bind:** The value is indexed by the test line number (e.g., `L10`) triggering the hold, correlating your code and the stored data.
3.  **Assert:** On subsequent runs, Holdify checks that the fresh value matches the one "held" at that line.

> [!TIP]
> **Mental Model:** Imagine the expected value is written directly in your test file at line X. Holdify simply moves that text into a separate file (indexed by `LX`) to keep your code clean, but the assertion remains strictly bound to that specific line. You can even inspect the YAML file for one-to-one feedback.

### Easy reconciliation

When your code changes intentionally, you need to reconcile the held values with the new values. You have three options:

1.  **Reconcile:** Run tests with the `--holdify-reconcile` option. Holdify will update any value that changed in the run tests.
    ```sh
    rake test TESTOPTS=--holdify-reconcile
    ```
    > [!WARNING]
    > Only use this when you are sure *all* new outputs are correct: everything will be overwritten!

2.  **Delete:** Delete the specific `*.yaml` file(s) and re-run the test(s). Ideally suited for when you want to reset specific test files _(and deleting is easier than using the ENV variable)_.

3.  **Selective update:** Temporarily append `!` to the method statements to reconcile and re-run the test. This forces Holdify to update the value.
  - `assert_hold` &rarr; `assert_hold!`
  - `must_hold` &rarr; `must_hold!`
  - `to_hold` &rarr; `to_hold!`

    > [!WARNING]
    > This stores the new value immediately but **raises an error** intentionally. This ensures you don't accidentally commit the `!` method. Revert to the standard method to pass the test.

### Inspecting Values

To quickly inspect the actual value from your code without changing anything, append `_?` to the statement and re-run the test. This prints the value to `stderr`.

- `assert_hold` &rarr; `assert_hold_?`
- `must_hold` &rarr; `must_hold_?`
- `to_hold` &rarr; `to_hold_?`

> [!NOTE]
> While `?` conventionally denotes a boolean predicate, Holdify uses it here as a **query term** _("Hold what value?")_. It is designed as a temporary development tool for quick feedback.

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

**Note:** The custom assertion must be a symbol (e.g., `:assert_something`) not an expectation (e.g., `:must_something`). The order of arguments (assertion symbol vs message) is flexible.

### Store Format

Holdify stores values in a standard YAML file named after your test file (e.g., `test_file.rb.yaml`). The keys are designed to be human-readable, allowing you to easily correlate stored values with your source code:

- **Line Matching:** Keys start with `L<num>` corresponding to the line number of the assertion in your test file (e.g., `L10`).
- **Multiple Hits:** If a single assertion line is executed multiple times (e.g., inside a loop), Holdify stores them as a list under the same key.

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

*   **Equality:** Stored values are verified using standard Minitest assertions, so ensure your custom objects implement `==` correctly.
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
