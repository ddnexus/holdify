# frozen_string_literal: true

require_relative '../test_helper'

describe 'holdify/create' do
  store_path = "#{__FILE__}#{Holdify::CONFIG[:ext]}"

  before do
    File.delete(store_path) if File.file?(store_path)
    Holdify.stores.delete(__FILE__)
  end

  it 'creates the store and the entry' do
    _, err = capture_io do
      expect('a new value').to_hold
    end
    _(err).must_match(/\[holdify\] Held new value for .*create_test.rb:15/)

    instance_variable_get(:@holdify).save
    value(store_path).path_must_exist
    _(File.read(store_path)).must_equal <<~STORE
      ---
      L15 79654db2592f319f915373af6d63d18cac6218f6:
      - a new value
    STORE
  end
end
