# frozen_string_literal: true

module Holdify
  # The *_hold Assertion/Expectation
  class Hold
    attr_reader :forced, :store, :test_loc, :session

    def initialize(test)
      @test    = test
      @path,   = test.method(test.name).source_location
      @store   = Holdify.stores(@path)
      @session = Hash.new { |h, k| h[k] = [] } # { lineno => [values] }
      @forced  = []                            # [ lines ]
      @added   = []                            # [ lines ]
    end

    def call(actual, force: false)
      @test_loc = find_test_loc
      lineno    = @test_loc.lineno
      raise "Could not find holdify statement at lineno #{lineno}" unless @store.xxh(lineno)

      @forced << lineno if force

      values = @store.get_values(lineno)
      index  = @session[lineno].size
      value  = if force || Holdify.reconcile
                 actual
               elsif values && index < values.size
                 values[index]
               else
                 @added << lineno
                 actual
               end

      @session[lineno] << value
      value
    end

    def save
      @added.each   { |lineno| warn "[holdify] Held new value for #{Holdify.relative(@path)}:#{lineno}" } unless Holdify.quiet
      @session.each { |lineno, values| @store.set_values(lineno, values) }
    end

    # Find the triggering LOC inside the test block/method
    def find_test_loc
      caller_locations(2).find do |location|
        next unless location.path == @path

        label  = location.base_label
        label == @test.name || label == '<top (required)>' || label == '<main>' || label.start_with?('<class:', '<module:')
      end
    end

    def warn_for(actual)
      warn("[holdify] The value from #{Holdify.relative(@test_loc.path)}:#{@test_loc.lineno} is:\n[holdify] => #{actual.inspect}")
    end

    def feedback(*) = Feedback.new(self, *).message
  end
end
