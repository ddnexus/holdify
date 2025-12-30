# frozen_string_literal: true

require 'test_helper'

# ensure there is no store
def delete_store
  FileUtils.rm_f("#{__FILE__}#{Holdify::CONFIG[:ext]}")
end

describe 'holdify/identical_cases' do
  it 'creates multiple key store' do
    delete_store
    assert_hold! 'stored_value'
    _(@holdify.forced).wont_be_empty
    @holdify.forced.clear
    delete_store
    expect('stored_value').to_hold
    expect('stored_value').to_hold
    expect('stored_value').to_hold
    expect('stored_value').to_hold
    expect('stored_value').to_hold
    expect('stored_value').to_hold
    # delete_store
  end
end
