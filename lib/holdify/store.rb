# frozen_string_literal: true

require 'forwardable'
require_relative 'source'
require_relative 'ledger'

module Holdify
  # Interface to the Source (code) and the Ledger (data)
  class Store
    extend Forwardable

    def initialize(path)
      @source = Source.new(path)
      @ledger = Ledger.new(path, @source)
    end

    def_delegator  :@source, :xxh_at
    def_delegators :@ledger, :get, :set, :save
  end
end
