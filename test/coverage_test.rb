# frozen_string_literal: true

require 'test_helper'
require 'fileutils'

class CoverageTest < Minitest::Test
  # rubocop:disable Minitest/NonExecutableTestMethod
  # A dummy test class to trigger the logic in before_teardown
  class BangTest < Minitest::Test
    def self.runnable_methods
      []
    end

    def test_bang
      assert_hold! 'value'
    end
  end

  # A dummy test class to trigger before_teardown when setup fails (@holdify is nil)
  class SetupFailureTest < Minitest::Test
    def self.runnable_methods
      []
    end

    def setup = raise('setup failure')
    def test_fail; end
  end

  # A dummy test class to trigger before_teardown when forced is true but failures is not empty
  class BangWithFailureTest < Minitest::Test
    def self.runnable_methods
      []
    end

    def test_bang_fail
      assert_hold! 'value'
      flunk 'failure'
    end
  end

  def test_bang_raises_error
    test = BangTest.new('test_bang')
    test.run

    assert_equal 1, test.failures.size
    assert_match(/remove the "!" suffix/, test.failures.first.message)
  ensure
    path = "#{File.expand_path(__FILE__)}.yaml"
    FileUtils.rm_f(path)
  end

  def test_setup_failure_covers_nil_holdify
    test = SetupFailureTest.new('test_fail')
    test.run

    assert_equal 1, test.failures.size
    assert_match(/setup failure/, test.failures.first.message)
  end

  def test_block_coverage
    # Trigger line 39: label.start_with?('block ')
    tap do
      assert_hold 'block_val'
    end
  ensure
    path = "#{File.expand_path(__FILE__)}.yaml"
    FileUtils.rm_f(path)
  end

  def test_quiet_mode
    Holdify.quiet = true
    assert_silent { assert_hold 'quiet_val' }
    Holdify.quiet = false
    assert_hold 'quiet_val_false'
  ensure
    Holdify.quiet = false
    path = "#{File.expand_path(__FILE__)}.yaml"
    FileUtils.rm_f(path)
  end

  def test_missing_assertion_in_source
    _r = Holdify.new(self)
    # rubocop:disable Style/EvalWithLocation
    error = assert_raises(RuntimeError) { eval("_r.hold('foo')", binding, __FILE__, 10_000) }
    # rubocop:enable Style/EvalWithLocation
    assert_match(/Could not find holdify statement at line 10000/, error.message)
  end

  def test_multiple_assertions
    assert_hold 'a'
    assert_hold 'b'
  ensure
    path = "#{File.expand_path(__FILE__)}.yaml"
    FileUtils.rm_f(path)
  end

  def test_bang_with_failure_skips_holdify_error
    test = BangWithFailureTest.new('test_bang_fail')
    test.run

    assert_equal 1, test.failures.size
    assert_equal 'failure', test.failures.first.message
  ensure
    path = "#{File.expand_path(__FILE__)}.yaml"
    FileUtils.rm_f(path)
  end
  # rubocop:enable Minitest/NonExecutableTestMethod
end
