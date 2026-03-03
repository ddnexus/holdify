# frozen_string_literal: true

require 'holdify'

# Implement the minitest plugin
module Minitest
  # Set the Holdify options
  def self.plugin_holdify_options(opts, options)
    opts.on '--holdify-reconcile', 'Reconcile the held values with the new ones (enables quiet)' do
      options[:holdify_reconcile] = true
      options[:holdify_quiet]     = true
    end
    opts.on '--holdify-quiet', 'Skip the warning on storing a new value' do
      options[:holdify_quiet] = true
    end
    opts.on '--holdify-no-git-diff', 'Disable git-diff' do
      options[:holdify_no_git_diff] = true
    end
    opts.on '--holdify-no-color', 'Disable colored output' do
      options[:holdify_no_color] = true
    end
    opts.on '--holdify-no-relative-paths', 'Disable relative paths in file references' do
      options[:holdify_no_relative_paths] = true
    end
    opts.on '--holdify-store-ext EXT', 'The yaml store extension (default .yaml)' do |ext|
      options[:holdify_store_ext] = ext
    end
  end

  # Register the after_run hook to persist all data
  def self.plugin_holdify_init(options)
    # :nocov:
    git         = system('git --version', out: File::NULL, err: File::NULL)
    Holdify.pwd = git ? `git rev-parse --show-toplevel`.strip : Dir.pwd
    # :nocov:

    Holdify.reconcile = options[:holdify_reconcile]
    Holdify.quiet     = options[:holdify_quiet]
    Holdify.git_diff  = git unless options[:holdify_no_git_diff]
    Holdify.color     = !ENV.key?('NO_COLOR') unless options[:holdify_no_color]
    Holdify.rel_paths = true unless options[:holdify_no_relative_paths]
    Holdify.store_ext = options[:holdify_store_ext] || '.yaml'

    Minitest.after_run do
      Holdify.persist_stores!
      Holdify.fresh_report
    end
  end

  # Patching Minitest::Assertion
  class Assertion
    remove_const :RE
    RE = /in [`'](?:[^']+[#.])?(?:assert|refute|flunk|pass|fail|raise|must|wont|to)/ # :nodoc:
  end

  # Reopen the minitest class
  class Test
    # Ensure store is tidied and saved after the test runs
    def before_teardown
      super
      return unless failures.empty? && @hold

      @hold.save
      return unless @hold.forced.any?

      path, = method(name).source_location
      msg   = +%([HOLDIFY] Reconciled values (Remove the "!" suffix to pass the test)\n)
      msg  << @hold.forced.uniq.map { |lineno| "  #{path}:#{lineno}" }.join("\n")

      flunk msg
    end
  end

  # Reopen the minitest module
  module Assertions
    # Main assertion
    def assert_hold(actual, *args, inspect: false, **)
      @hold ||= Holdify::Hold.new(self)
      assertion, message = args
      assertion, message = message, assertion unless assertion.nil? || assertion.is_a?(Symbol)
      expected = @hold.(actual, **)

      begin
        if inspect
          message = ['[HOLDIFY] Inspect actual value (Remove the "?" suffix to pass the test)', message].compact.join(' ')
          flunk(message)
        elsif actual.nil?
          assert_nil expected, message
        else
          send(assertion || :assert_equal, expected, actual, message)
        end
      rescue Minitest::Assertion => e
        feedback = @hold.feedback(e.location, expected, actual, message)
        raise(Minitest::Assertion, feedback)
      end

      expected
    end

    # Force store the current value
    def assert_hold!(*, **) = assert_hold(*, **, force: true)

    # Print to STDERR the actual value
    def assert_hold?(*, **) = assert_hold(*, **, inspect: true)
  end

  # Register expectations only if minitest/spec is loaded; ensure the right class in 6.0 and < 6.0
  # :nocov:
  if (expectation_class = defined?(Spec) && (defined?(Expectation) ? Expectation : Expectations))
    %w[hold hold! hold?].each do |suffix|
      expectation_class.infect_an_assertion :"assert_#{suffix}", :"must_#{suffix}", :reverse
      expectation_class.alias_method :"to_#{suffix}", :"must_#{suffix}"
    end
  end
  # :nocov:
end
