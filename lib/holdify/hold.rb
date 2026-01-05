# frozen_string_literal: true

module Holdify
  # The *_hold statement (Assertion/Expectation)
  class Hold
    attr_reader :forced

    def initialize(test)
      @test    = test
      @path,   = test.method(test.name).source_location
      @store   = Holdify.stores[@path] ||= Store.new(@path)
      @session = Hash.new { |h, k| h[k] = [] } # { lineno => [values] }
      @forced  = []                            # [ "file:lineno" ]
      @added   = []                            # [ "file:lineno" ]
      @index   = {}                            # { lineno => index }
      @counts  = Hash.new(0)                   # { id => count }
    end

    def call(actual, force: false)
      location = find_location
      lineno   = location.lineno
      id       = @store.id_at(lineno)
      raise "Could not find holdify statement at line #{lineno}" unless id

      unless @index.key?(lineno)
        @index[lineno] = @counts[id]
        @counts[id] += 1
      end
      index = @index[lineno]

      @session[lineno] << actual
      @forced << "#{location.path}:#{lineno}" if force

      return actual if force || Holdify.reconcile

      stored = @store.stored(id, index)
      index  = @session[lineno].size - 1
      return stored[index] if stored && index < stored.size

      @added << "#{location.path}:#{lineno}"
      actual
    end

    def save
      return unless @test.failures.empty?

      @added.each { |loc| warn "[holdify] Held new value for #{loc}" } unless Holdify.quiet
      @session.each do |lineno, values|
        id    = @store.id_at(lineno)
        index = @index[lineno]
        @store.update(lineno, id, values, index)
      end
      @store.save
    end

    def find_location
      caller_locations.find do |location|
        next unless location.path == @path

        label = location.base_label
        label == @test.name || label == '<top (required)>' || label == '<main>' || label.start_with?('<class:', '<module:')
      end
    end
  end
end
