# frozen_string_literal: true

require 'test_helper'

describe 'holdify/identical_cases' do
  it 'creates multiple key store' do
    expect('stored_value').to_hold
    expect('stored_value').to_hold
    expect('stored_value').to_hold
    expect('stored_value').to_hold
    expect('stored_value').to_hold
    expect('stored_value').to_hold
  end

  it 'handles identical lines with different values' do
    # First run: create
    assert_hold 'value 1'
    assert_hold 'value 2'
    @hold.save

    # Reset memory only (keep file)
    path = File.expand_path(__FILE__)
    Holdify.stores.delete(path)
    @hold = Holdify::Hold.new(self)

    # Second run: verify
    assert_hold 'value 1'
    assert_hold 'value 2'
  end
end
