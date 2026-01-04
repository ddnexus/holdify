# frozen_string_literal: true

module Holdify
  # The *_hold statement (Assertion/Expectation)
  class Hold
    attr_reader :forced

    def initialize(test)
      @test    = test
      @path,   = test.method(test.name).source_location
      @store   = Holdify.stores[@path] ||= Store.new(@path)
      @session = Hash.new { |h, k| h[k] = [] }
      @forced  = []
      @added   = []
    end

    def call(actual, force: false)
      location = find_location
      id       = @store.id_at(location.lineno)
      raise "Could not find holdify statement at line #{location.lineno}" unless id

      @session[id] << actual
      @forced << "#{location.path}:#{location.lineno}" if force

      return actual if force || Holdify.reconcile

      stored = @store.stored(id)
      index  = @session[id].size - 1
      return stored[index] if stored && index < stored.size

      @added << "#{location.path}:#{location.lineno}"
      actual
    end

    def save
      return unless @test.failures.empty?

      @added.each { |loc| warn "[holdify] Held new value for #{loc}" } unless Holdify.quiet
      @session.each { |id, values| @store.update(id, values) }
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
