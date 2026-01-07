# frozen_string_literal: true

require_relative 'holdify/store'
require_relative 'holdify/hold'

# The container module
module Holdify
  VERSION = '1.1.1'
  CONFIG  = { ext: '.yaml' }.freeze

  class << self
    attr_accessor :reconcile, :quiet
    attr_writer :pretty

    def stores = @stores ||= {}

    def pretty
      return @pretty unless @pretty.nil?

      @pretty = $stdout.tty? && !ENV.key?('NO_COLOR') && ENV['TERM'] != 'dumb' &&
                system('git --version', out: File::NULL, err: File::NULL)
    end
  end
end
