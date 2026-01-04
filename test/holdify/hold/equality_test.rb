# frozen_string_literal: true

require 'test_helper'
require 'minitest/unordered'

module Minitest
  module Assertions
    # stupid assertion in real world, but good for testing
    def assert_equal_insensitive(expected, actual, msg = nil)
      assert_equal expected.downcase, actual.downcase, msg
    end
  end
end

describe 'holdify/equality' do
  it 'sticks :assert_equal_insensitive' do
    # the store contains 'MIXED_case' instead of 'mixed_CASE' (edit manually if rebuilt)
    expect('mixed_CASE').to_hold :assert_equal_insensitive
    assert_hold 'mixed_CASE', :assert_equal_insensitive
  end

  describe Holdify do
    it 'sticks nested describe' do
      value = 'a value'
      expect(value).to_hold
    end
  end

  it 'sticks :assert_equal_unordered' do
    # assert_equal_unordered [2,1,3], [1,2,3]
    # the store contains [2,1,3] instead of [1,2,3] (edit manually if rebuilt)
    array = [1, 2, 3]
    _(array).must_hold :assert_equal_unordered
    value(array).must_hold :assert_equal_unordered
    expect(array).to_hold :assert_equal_unordered
    assert_hold array, :assert_equal_unordered
  end

  it 'sticks :assert_nil' do
    expect(nil).to_hold
  end

  it 'sticks empty value' do
    expect("").to_hold
  end
end
