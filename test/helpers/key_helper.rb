# frozen_string_literal: true

module KeyHelper
  # Patch Holdify to capture the key used during execution
  module Capture
    def store_key
      @store_key
    end

    def call(actual, force: false)
      location   = find_location
      xxh        = @store.xxh(location.lineno)
      @store_key = "L#{location.lineno} #{xxh}" if xxh
      super
    end

    def save
      super
      @added.clear
    end
  end

  def last_key
    @hold.store_key
  end
end

Holdify::Hold.prepend(KeyHelper::Capture)

module Minitest
  class Test
    include KeyHelper
  end
end
