# frozen_string_literal: true

require 'digest/sha1'
require_relative 'holdify/store'

# Add description
class Holdify
  VERSION = '1.0.1'
  CONFIG  = { ext: '.yaml' }.freeze

  class << self
    attr_accessor :reconcile, :quiet

    def stores = @stores ||= {}
  end

  attr_reader :forced

  def initialize(test)
    @test    = test
    @path,   = test.method(test.name).source_location
    @store   = self.class.stores[@path] ||= Store.new(@path)
    @session = Hash.new { |h, k| h[k] = [] }
    @forced  = []
  end

  def hold(actual, force: false)
    location = find_location
    id       = @store.id_at(location.lineno)
    raise "Could not find holdify statement at line #{location.lineno}" unless id

    @session[id] << actual
    @forced << "#{location.path}:#{location.lineno}" if force

    return actual if force || self.class.reconcile

    stored = @store.stored(id)
    index  = @session[id].size - 1
    return stored[index] if stored && index < stored.size

    # :nocov:
    warn "[holdify] Held new value for #{location.path}:#{location.lineno}" unless self.class.quiet
    # :nocov:
    actual
  end

  def save
    return unless @test.failures.empty?

    @session.each { |id, values| @store.update(id, values) }
    @store.save
  end

  def find_location
    caller_locations.find do |location|
      next unless location.path == @path

      label = location.base_label
      # :nocov:
      label = ::Regexp.last_match(1) if label.start_with?('block ') && label =~ / in (.+)$/
      # :nocov:

      label == @test.name ||
        label == '<top (required)>' ||
        label == '<main>' ||
        label.start_with?('<class:', '<module:')
    end
  end
end
