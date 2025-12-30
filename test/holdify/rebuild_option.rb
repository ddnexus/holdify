# frozen_string_literal: true

# This file is run via system call from test/holdify/rebuild_test.rb
# It is NOT named *_test.rb to avoid being picked up by the default rake task
require_relative '../test_helper'

describe 'holdify/rebuild_option' do
  it 'rebuilds the store' do
    store_path = "#{__FILE__}#{Holdify::CONFIG[:ext]}"
    # 1. Verify Rebuild: The flag should have triggered deletion in Holdify.new
    value(store_path).path_wont_exist
    expect('store_value').to_hold
    # 2. Verify Creation: We must force a save because Holdify now buffers writes
    instance_variable_get(:@holdify).save
    value(store_path).path_must_exist
  end
end
