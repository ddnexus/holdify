# frozen_string_literal: true

module KeyHelper
  # Patch Holdify to capture the key used during execution
  module Capture
    def store_key
      @store_key
    end

    def call(actual, force: false)
      @test_loc  = find_test_loc
      xxh        = @store.xxh(@test_loc.lineno)
      @store_key = "L#{@test_loc.lineno}-#{xxh}" if xxh
      super
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
