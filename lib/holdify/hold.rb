# frozen_string_literal: true

module Holdify
  # The *_hold statement (Assertion/Expectation)
  class Hold
    attr_reader :forced

    def initialize(test)
      @test    = test
      @path,   = test.method(test.name).source_location
      @store   = Holdify.stores[@path] ||= Store.new(@path)
      @session = Hash.new { |h, k| h[k] = [] } # { line => [values] }
      @forced  = []                            # [ "file:line" ]
      @added   = []                            # [ "file:line" ]
    end

    def call(actual, force: false)
      location = find_location
      line     = location.lineno
      raise "Could not find holdify statement at line #{line}" unless @store.sha_at(line)

      @session[line] << actual
      @forced << "#{@path}:#{line}" if force

      return actual if force || Holdify.reconcile

      # Expected value
      values = @store.get(line)
      index  = @session[line].size - 1
      return values[index] if values && index < values.size

      @added << "#{@path}:#{line}"
      actual
    end

    def save
      return unless @test.failures.empty?

      @added.each   { |loc| warn "[holdify] Held new value for #{loc}" } unless Holdify.quiet
      @session.each { |line, values| @store.set(line, values) }
      @store.save
    end

    # Find the location in the test that triggered the hold
    def find_location
      caller_locations.find do |location|
        next unless location.path == @path

        label = location.base_label
        label == @test.name || label == '<top (required)>' || label == '<main>' || label.start_with?('<class:', '<module:')
      end
    end
  end
end
