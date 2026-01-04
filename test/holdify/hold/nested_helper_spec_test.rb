# frozen_string_literal: true

require 'test_helper'

def helper_method(value)
  assert_hold value
end

describe 'NestedHelperSpec' do
  def nested_wrapper(val)
    helper_method(val)
  end

  it 'direct call' do
    helper_method('direct')
  end

  it 'loop call' do
    %w[loop1 loop2].each do |val|
      helper_method(val)
    end
  end

  it 'nested helper call' do
    nested_wrapper('nested')
  end

  it 'block call' do
    2.times { helper_method('block') }
  end

  it 'lambda call' do
    -> { helper_method('lambda') }.call
  end

  it 'tap' do
    tap { helper_method('tap') }
  end

  it 'proc call' do
    proc { helper_method('proc') }.call
  end
end
