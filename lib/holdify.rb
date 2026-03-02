# frozen_string_literal: true

require_relative 'holdify/hold'
require_relative 'holdify/feedback'
require_relative 'holdify/source'
require_relative 'holdify/store'

# The container module
module Holdify
  VERSION = '1.3.1'

  class << self
    attr_accessor :reconcile, :quiet, :git, :pwd, :color, :rel_paths, :store_ext

    def persist_all! = @stores&.each_value(&:persist)

    def relative(path)
      return path unless rel_paths

      path.sub(%r{^#{pwd}/}, '')
    end

    def stores(path = nil)
      return @stores unless path

      @mutex.synchronize do
        @stores[path] ||= Store.new(path)
      end
    end
  end
  @mutex  = Mutex.new
  @stores = {}
end
