# frozen_string_literal: true

require_relative 'holdify/hold'
require_relative 'holdify/feedback'
require_relative 'holdify/source'
require_relative 'holdify/store'

# The container module
module Holdify
  VERSION = '1.3.5'

  @fresh_mutex  = Mutex.new
  @fresh        = []
  @stores_mutex = Mutex.new
  @stores       = {}

  class << self
    attr_accessor :reconcile, :quiet, :git_diff, :pwd, :color, :rel_paths, :store_ext

    def push_fresh(test_ref)
      @fresh_mutex.synchronize do
        @fresh << test_ref
      end
    end

    def warn_fresh_values
      return if quiet

      @fresh_mutex.synchronize do
        return if @fresh.empty?

        warn "[HOLDIFY] Fresh value held for:\n#{@fresh.uniq.sort.map { "  #{_1}" }.join("\n")}"
      end
    end

    def stores(path = nil)
      @stores_mutex.synchronize do
        return @stores unless path

        @stores[path] ||= Store.new(path)
      end
    end

    def persist_stores!
      @stores_mutex.synchronize do
        @stores&.each_value(&:persist)
      end
    end

    def relativize(path)
      return path unless rel_paths

      path.sub(%r{^#{pwd}/}, '')
    end
  end
end
