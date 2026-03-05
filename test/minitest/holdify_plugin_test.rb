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

  class SetupFeedbackTest < Minitest::Test
    def self.runnable_methods = []
    def setup = raise('setup failure')
    def test_fail; end
  end

  class BangWithFeedbackTest < Minitest::Test
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

  def setup
    @original_config = { reconcile: Holdify.reconcile,
                         quiet:     Holdify.quiet,
                         git:       Holdify.git_diff,
                         color:     Holdify.color,
                         rel_paths: Holdify.rel_paths,
                         store_ext: Holdify.store_ext }
  end

  def teardown
    path = File.expand_path(__FILE__)
    FileUtils.rm_f("#{path}.yaml")
    Holdify.stores.delete(path)

    Holdify.reconcile = @original_config[:reconcile]
    Holdify.quiet     = @original_config[:quiet]
    Holdify.git_diff  = @original_config[:git]
    Holdify.color     = @original_config[:color]
    Holdify.rel_paths = @original_config[:rel_paths]
    Holdify.store_ext = @original_config[:store_ext]
  end

  # rubocop:disable Minitest/NonExecutableTestMethod
  def test_bang_raises_error
    test = BangTest.new('test_bang')
    test.run

    assert_equal 1, test.failures.size
    assert_match(/Remove the "!" suffix/, test.failures.first.message)
  end

  def test_setup_feedback_covers_nil_holdify
    test = SetupFeedbackTest.new('test_fail')
    test.run

    assert_equal 1, test.failures.size
    assert_match(/setup failure/, test.failures.first.message)
  end

  def test_bang_with_feedback_skips_holdify_error
    test = BangWithFeedbackTest.new('test_bang_fail')
    test.run

    assert_equal 1, test.failures.size
    assert_equal 'failure', test.failures.first.message
  end

  def test_handles_options_parsing  # rubocop:disable Minitest/MultipleAssertions
    options = {}
    opts    = OptionParser.new
    Minitest.plugin_holdify_options(opts, options)

    opts.parse! %w[--holdify-reconcile --holdify-quiet --holdify-no-git-diff
                   --holdify-no-color --holdify-absolute-paths --holdify-store-ext .json]

    assert options[:holdify_reconcile]
    assert options[:holdify_quiet]
    assert options[:holdify_no_git_diff]
    assert options[:holdify_no_color]
    assert options[:holdify_absolute_paths]
    assert_equal '.json', options[:holdify_store_ext]
  end

  def test_plugin_init_defaults # rubocop:disable Minitest/MultipleAssertions
    Minitest.plugin_holdify_init({})

    refute Holdify.reconcile
    refute Holdify.quiet
    assert_includes [true, false, nil], Holdify.git_diff
    assert_includes [true, false], Holdify.color
    assert Holdify.rel_paths
    assert_equal '.yaml', Holdify.store_ext
  end

  def test_plugin_init_with_options  # rubocop:disable Minitest/MultipleAssertions
    # Clear defaults to ensure we are testing the options
    Holdify.git_diff  = nil
    Holdify.color     = nil
    Holdify.rel_paths = nil

    options = {
      holdify_reconcile:      true,
      holdify_quiet:          true,
      holdify_no_git_diff:    true,
      holdify_no_color:       true,
      holdify_absolute_paths: true,
      holdify_store_ext:      '.json'
    }

    Minitest.plugin_holdify_init(options)

    assert Holdify.reconcile
    assert Holdify.quiet
    assert_nil Holdify.git_diff
    assert_nil Holdify.color
    assert_nil Holdify.rel_paths
    assert_equal '.json', Holdify.store_ext
  end

  def test_assert_hold_question_fail_test
    test = QuestionFailTest.new('test_question_fail')
    _out, err = capture_io do
      test.run
    end

    assert_equal 1, test.failures.size
    refute_match(/\[holdify\] =>/, err)
  end
  # rubocop:enable Minitest/NonExecutableTestMethod
end
