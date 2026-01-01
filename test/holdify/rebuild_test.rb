# frozen_string_literal: true

require_relative '../test_helper'

describe 'holdify/reconcile' do
  it 'runs the reconcile option test' do
    # Run the isolated test file with the reconcile flag
    # This ensures the flag is tested without affecting the main suite
    cmd = 'SKIP_COVERAGE=true ruby -Ilib:test test/holdify/rebuild_option.rb --holdify-reconcile'

    # Capture output to keep main test output clean, unless it fails
    output = `#{cmd} 2>&1`
    result = $?.success? # rubocop:disable Style/SpecialGlobalVars

    warn output unless result
    _(result).must_equal true
  end
end
