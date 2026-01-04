# frozen_string_literal: true

require 'test_helper'

describe 'holdify/identical_cases' do
  def delete_store
    path = File.expand_path(__FILE__)
    FileUtils.rm_f("#{path}#{Holdify::CONFIG[:ext]}")
    Holdify.stores.delete(path)
    @hold = Holdify::Hold.new(self)
  end

  it 'creates multiple key store' do
    delete_store
    assert_hold! 'stored_value'
    _(@hold.forced).wont_be_empty
    @hold.forced.clear
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
