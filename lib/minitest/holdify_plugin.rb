# frozen_string_literal: true

require 'holdify'

# Implement the minitest plugin
module Minitest
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
      @hold&.save
      return unless @hold&.forced&.any? && failures.empty?

      msg = <<~MSG.chomp
        [holdify] the value has been stored: remove the "!" suffix to pass the test
        #{@hold.forced.uniq.map { |l| "  #{l}" }.join("\n")}
      MSG
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

      if actual.nil?
        assert_nil expected, message
      else
        send(assertion || :assert_equal, expected, actual, message)
      end

      if inspect
        location = @hold.find_location
        warn "[holdify] The value from #{location.path}:#{location.lineno} is:\n[holdify] => #{actual.inspect}"
      end

      expected
    end

    # Temporarily used to store the actual value, useful for reconciliation of expected changed values
    def assert_hold!(*, **) = assert_hold(*, **, force: true)

    # Temporarily used for development feedback to print to STDERR the actual value
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
