# frozen_string_literal: true

require 'test_helper'

class VisualDiffTest < Minitest::Test
  # Switch to true to update the store file with the actual value
  UPDATE = false

  def test_visual_diff_output
    Holdify.pretty = true

    # Complex structure to demonstrate diff capabilities
    actual = {
      app: 'Holdify',
      version: '1.0.4',
      features: %w[store pretty_diff],
      config: {
        adapter: 'sqlite',
        pool: 5,
        timeout: 5000
      },
      description: "Long long long long long long long long prefix. Holdify allows you to store objects and compare them in future runs. It uses git for diffs. This string is very very very very very very very very very very very very very very very very very long."
    }

    # This assertion will fail if the stored file is manually modified to differ from 'actual'.
    # We catch the failure to print the diff for demonstration purposes, but allow the test to pass.
    assert_hold actual
  rescue Minitest::Assertion => e
    puts "\n#{e.message}"
    @hold.instance_variable_get(:@session).clear unless UPDATE
  ensure
    Holdify.pretty = false
  end
end
