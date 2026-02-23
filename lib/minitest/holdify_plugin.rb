# frozen_string_literal: true

require 'holdify'
require 'holdify/failure'

# Implement the minitest plugin
module Minitest
  # Register the after_run hook to persist all data
  def self.plugin_holdify_init(_options)
    Minitest.after_run { Holdify.persist_all! }
  end

  # Set the Holdify options
  def self.plugin_holdify_options(opts, _options)
    opts.on '--holdify-reconcile', 'Reconcile the held values with the new ones' do
      Holdify.reconcile = true
      Holdify.quiet     = true
    end

    opts.on '--holdify-quiet', 'Skip the warning on storing a new value' do
      Holdify.quiet = true
    end
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
      msg   = +%([holdify] the value has been stored: remove the "!" suffix to pass the test\n)
      msg  << @hold.forced.uniq.map { |line| "  #{path}:#{line}" }.join("\n")

      raise Minitest::Assertion, msg
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
        if actual.nil?
          assert_nil expected, message
        else
          send(assertion || :assert_equal, expected, actual, message)
        end
      rescue Minitest::Assertion => e
        location = @hold.find_location
        metadata = @hold.store.lookup(location.lineno, @hold.current_index(location.lineno))
        hold_msg = Holdify::Failure.new(expected, actual, e.message, metadata:, location:).message

        msg = message ? "#{message}\n#{hold_msg}" : hold_msg
        raise Minitest::Assertion, msg
      end

      if inspect
        location = @hold.find_location
        warn "[holdify] The value from #{location.path}:#{location.lineno} is:\n[holdify] => #{actual.inspect}"
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
