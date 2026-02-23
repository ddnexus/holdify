# frozen_string_literal: true

require 'test_helper'
require 'optparse'

class HoldifyPluginTest < Minitest::Test
  # Dummy classes for testing plugin hooks
  class BangTest < Minitest::Test
    def self.runnable_methods = []

    def test_bang
      assert_hold! 'value'
    end
  end

  class SetupFailureTest < Minitest::Test
    def self.runnable_methods = []
    def setup = raise('setup failure')
    def test_fail; end
  end

  class BangWithFailureTest < Minitest::Test
    def self.runnable_methods = []

    def test_bang_fail
      assert_hold! 'value'
      flunk 'failure'
    end
  end

  class QuestionFailTest < Minitest::Test
    def self.runnable_methods = []

    def test_question_fail # rubocop:disable Naming/PredicateMethod
      assert_hold? 'value', :refute_equal
    end
  end

  def teardown
    path = File.expand_path(__FILE__)
    FileUtils.rm_f("#{path}.yaml")
    Holdify.stores.delete(path)
    Holdify.quiet = false
  end

  # rubocop:disable Minitest/NonExecutableTestMethod
  def test_bang_raises_error
    test = BangTest.new('test_bang')
    test.run

    assert_equal 1, test.failures.size
    assert_match(/remove the "!" suffix/, test.failures.first.message)
  end

  def test_setup_failure_covers_nil_holdify
    test = SetupFailureTest.new('test_fail')
    test.run

    assert_equal 1, test.failures.size
    assert_match(/setup failure/, test.failures.first.message)
  end

  def test_bang_with_failure_skips_holdify_error
    test = BangWithFailureTest.new('test_bang_fail')
    test.run

    assert_equal 1, test.failures.size
    assert_equal 'failure', test.failures.first.message
  end

  def test_handles_reconcile_option_parsing
    opts = OptionParser.new
    Minitest.plugin_holdify_options(opts, {})
    opts.parse!(['--holdify-reconcile'])
    assert Holdify.reconcile
  ensure
    Holdify.reconcile = false
    Holdify.quiet = false
  end

  def test_handles_quiet_option_parsing
    opts = OptionParser.new
    Minitest.plugin_holdify_options(opts, {})
    opts.parse!(['--holdify-quiet'])
    assert Holdify.quiet
  ensure
    Holdify.quiet = false
  end

  def test_assert_hold_question_prints_nil
    result = :not_nil
    _out, err = capture_io do
      result = assert_hold? nil
    end
    assert_nil result
    assert_match(/\[holdify\] => nil/, err)
  end

  def test_assert_hold_question_fail_test
    test = QuestionFailTest.new('test_question_fail')
    _out, err = capture_io do
      test.run
    end

    assert_equal 1, test.failures.size
    refute_match(/\[holdify\] =>/, err)
  end

  def test_assert_hold_uses_pretty_diff
    test = Minitest::Test.new('dummy')

    mock_store = Object.new
    def mock_store.lookup(_, _) = { path: 'path', line: 1, key: 'key' }

    mock_hold = Minitest::Mock.new
    mock_hold.expect :call, 'expected', ['actual']
    mock_hold.expect :find_location, Struct.new(:lineno).new(1)
    mock_hold.expect :current_index, 0, [1]
    mock_hold.expect :store, mock_store

    mock_diff = Minitest::Mock.new
    mock_diff.expect :message, 'DIFF'

    Holdify::Hold.stub :new, proc { mock_hold } do
      Holdify::Failure.stub :new, mock_diff do
        e = assert_raises(Minitest::Assertion) do
          test.assert_hold('actual')
        end
        assert_equal 'DIFF', e.message
      end
    end
    mock_diff.verify
  end

  def test_assert_hold_uses_pretty_diff_with_custom_message
    test = Minitest::Test.new('dummy')

    mock_store = Object.new
    def mock_store.lookup(_, _) = { path: 'path', line: 1, key: 'key' }

    mock_hold = Minitest::Mock.new
    mock_hold.expect :call, 'expected', ['actual']
    mock_hold.expect :find_location, Struct.new(:lineno).new(1)
    mock_hold.expect :current_index, 0, [1]
    mock_hold.expect :store, mock_store

    mock_diff = Minitest::Mock.new
    mock_diff.expect :message, 'DIFF'

    Holdify::Hold.stub :new, proc { mock_hold } do
      Holdify::Failure.stub :new, mock_diff do
        e = assert_raises(Minitest::Assertion) do
          test.assert_hold('actual', 'custom msg')
        end
        assert_equal "custom msg\nDIFF", e.message
      end
    end
    mock_diff.verify
  end
  # rubocop:enable Minitest/NonExecutableTestMethod
end
