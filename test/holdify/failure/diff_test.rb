# frozen_string_literal: true

require 'test_helper'

class DiffTest < Minitest::Test
  # Switch to true to update the store file with the actual value
  UPDATE = false

  def loop_helper(actual)
    assert_hold({ array: %w[line1 line2 line3] })
    assert_hold actual
  end

  def test_diff_output
    assert_hold %w[one two three]

    if UPDATE
      actual = { app:         'Holdify',
                 version:     '1.1.1',
                 features:    %w[store pretty_diff],
                 config:      { adapter: 'sqlite',
                                pool:    10,
                                timeout: 5000 },
                 description: "Holdify allows you to easily hold objects and compare them in future runs. It uses git for diffs." }
    else
      # Complex structure to demonstrate diff capabilities
      actual = { app:         'Holdify',
                 version:     '1.0.4',
                 features:    %w[store pretty_diff],
                 config:      { pool:    5,
                                timeout: 5000,
                                tz: 'EST' },
                 description: "Holdify allows you to automatically hold objects and compare them in future runs. It runs git diffs." }
    end

    # This assertion will fail if the stored file is manually modified to differ from 'actual'.
    # We catch the failure to print the diff for demonstration purposes, but allow the test to pass.
    loop_helper(actual)
  rescue Minitest::Assertion => e
    puts "\n#{e.message}"
    @hold.instance_variable_get(:@session).clear unless UPDATE
  end
end
