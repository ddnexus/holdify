# frozen_string_literal: true

require_relative 'holdify/store'
require_relative 'holdify/hold'

# The container module
module Holdify
  VERSION = '1.1.3'
  CONFIG  = { ext: '.yaml' }.freeze

  class << self
    attr_accessor :reconcile, :quiet

    def config
      @config ||= { git:   system('git --version', out: File::NULL, err: File::NULL),
                    color: !ENV.key?('NO_COLOR') }
    end

    def stores(path = nil)
      return @stores unless path

      @mutex.synchronize do
        @stores[path] ||= Store.new(path)
      end
    end

    def persist_all!
      @stores&.each_value(&:persist)
    end
  end
  @mutex  = Mutex.new
  @stores = {}
end
