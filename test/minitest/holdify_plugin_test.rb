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

  def test_handles_pretty_option_parsing
    opts = OptionParser.new
    Minitest.plugin_holdify_options(opts, {})
    opts.parse!(['--holdify-pretty'])
    assert Holdify.pretty
  ensure
    Holdify.pretty = false
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
    Holdify.pretty = true
    test = Minitest::Test.new('dummy')

    mock_hold = Minitest::Mock.new
    mock_hold.expect :call, 'expected', ['actual']

    Holdify::Hold.stub :new, ->(_) { mock_hold } do
      Holdify::Pretty.stub :call, 'PRETTY_DIFF' do
        e = assert_raises(Minitest::Assertion) do
          test.assert_hold('actual')
        end
        assert_equal 'PRETTY_DIFF', e.message
      end
    end
  ensure
    Holdify.pretty = false
  end

  def test_assert_hold_falls_back_when_pretty_diff_returns_nil
    Holdify.pretty = true
    test = Minitest::Test.new('dummy')

    mock_hold = Minitest::Mock.new
    mock_hold.expect :call, 'expected', ['actual']

    Holdify::Hold.stub :new, ->(_) { mock_hold } do
      Holdify::Pretty.stub :call, nil do
        e = assert_raises(Minitest::Assertion) do
          test.assert_hold('actual')
        end
        assert_match(/Expected: "expected"/, e.message)
      end
    end
  ensure
    Holdify.pretty = false
  end

  def test_assert_hold_uses_pretty_diff_with_custom_message
    Holdify.pretty = true
    test = Minitest::Test.new('dummy')

    mock_hold = Minitest::Mock.new
    mock_hold.expect :call, 'expected', ['actual']

    Holdify::Hold.stub :new, ->(_) { mock_hold } do
      Holdify::Pretty.stub :call, 'PRETTY_DIFF' do
        e = assert_raises(Minitest::Assertion) do
          test.assert_hold('actual', 'custom msg')
        end
        assert_equal "custom msg\nPRETTY_DIFF", e.message
      end
    end
  ensure
    Holdify.pretty = false
  end
  # rubocop:enable Minitest/NonExecutableTestMethod
end
