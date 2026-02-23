# frozen_string_literal: true

module Holdify
  # The *_hold statement (Assertion/Expectation)
  class Hold
    attr_reader :forced, :store

    def initialize(test)
      @test    = test
      @path,   = test.method(test.name).source_location
      @store   = Holdify.stores(@path)
      @session = Hash.new { |h, k| h[k] = [] } # { line => [values] }
      @forced  = []                            # [ lines ]
      @added   = []                            # [ lines ]
    end

    def call(actual, force: false)
      location = find_location
      line     = location.lineno
      raise "Could not find holdify statement at line #{line}" unless @store.xxh(line)

      @forced << line if force

      values = @store.get(line)
      index  = @session[line].size
      value  = if force || Holdify.reconcile
                 actual
               elsif values && index < values.size
                 values[index]
               else
                 @added << line
                 actual
               end

      @session[line] << value
      value
    end

    def save
      @added.each   { |line| warn "[holdify] Held new value for #{@path}:#{line}" } unless Holdify.quiet
      @session.each { |line, values| @store.set(line, values) }
    end

    # The index of the current test/value
    def current_index(line) = @session[line].size - 1

    # Find the location in the test that triggered the hold
    def find_location
      caller_locations(2).find do |location|
        next unless location.path == @path

        label = location.base_label
        label == @test.name || label == '<top (required)>' || label == '<main>' || label.start_with?('<class:', '<module:')
      end
    end
  end
end
