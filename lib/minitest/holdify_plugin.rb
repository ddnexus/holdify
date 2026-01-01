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
    # :nocov:
    opts.on '--holdify-quiet', 'Skip the warning on storing a new value' do
      Holdify.quiet = true
    end
    # :nocov:
  end

  # Reopen the minitest class
  class Test
    # Create the @holdify instance for each test
    def after_setup
      super
      @holdify ||= Holdify.new(self)   # rubocop:disable Naming/MemoizedInstanceVariableName
    end

    # Ensure store is tidied and saved after the test runs
    def before_teardown
      super
      @holdify&.save
      return unless @holdify&.forced&.any? && failures.empty?

      msg = <<~MSG.chomp
        [holdify] the value has been stored: remove the "!" suffix to pass the test
        #{@holdify.forced.uniq.map { |l| "  #{l}" }.join("\n")}
      MSG
      raise Minitest::Assertion, msg
    end
  end

  # Reopen the minitest module
  module Assertions
    # Main assertion
    def assert_hold(actual, *args)
      @holdify ||= Holdify.new(self)
      assertion, message = args
      assertion, message = message, assertion unless assertion.nil? || assertion.is_a?(Symbol)

      expected = @holdify.hold(actual)
      if actual.nil?
        assert_nil expected, message
      else
        send(assertion || :assert_equal, expected, actual, message)
      end
    end

    # Temporarily used to store the actual value, useful for reconciliation of expected changed values
    def assert_hold!(actual, *)
      @holdify ||= Holdify.new(self)
      @holdify.hold(actual, force: true)
    end

    # Temporarily used for development feedback to print to STDERR the actual value
    def assert_hold_?(actual, *)
      @holdify ||= Holdify.new(self)
      location = @holdify.find_location
      warn "[holdify] Actual value from: #{location.path}:#{location.lineno}\n=> #{actual.inspect}"
      @holdify.hold(actual)
    end
  end

  # Register expectations only if minitest/spec is loaded; ensure the right class in 6.0 and < 6.0
  # :nocov:
  if (expectation_class = defined?(Spec) && (defined?(Expectation) ? Expectation : Expectations))
    %w[hold hold! hold_?].each do |suffix|
      expectation_class.infect_an_assertion :"assert_#{suffix}", :"must_#{suffix}", :reverse
      expectation_class.alias_method :"to_#{suffix}", :"must_#{suffix}"
    end
  end
  # :nocov:
end
