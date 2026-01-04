# frozen_string_literal: true

require_relative 'holdify/store'
require_relative 'holdify/hold'

# Add description
module Holdify
  VERSION = '1.0.2'
  CONFIG  = { ext: '.yaml' }.freeze

  class << self
    attr_accessor :reconcile, :quiet

    def stores = @stores ||= {}
  end
end
