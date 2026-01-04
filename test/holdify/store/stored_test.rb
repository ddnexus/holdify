# frozen_string_literal: true

require 'test_helper'
require 'time'

describe 'holdify/stored' do
  it 'sticks entry with stored value' do
    _('stored_value').must_hold
    assert_hold 'stored_value'
    _(5..34).must_hold
    assert_hold 5..34
    _([1, 4, 5, 6]).must_hold
    assert_hold [1, 4, 5, 6]
    _(a: 23, b: { c: ['a', 5] }).must_hold
    assert_hold({ a: 23, b: { c: ['a', 5] } })
    _(Time.parse('2021-05-16 12:33:31.101458598 +00:00')).must_hold
    assert_hold(Time.parse('2021-05-16 12:33:31.101458598 +00:00'))
  end

  it 'accepts all argument combinations' do
    # 1. No extra args
    assert_hold 'plain'
    _('plain').must_hold
    # 2. Only Assertion
    assert_hold 'assertion only', :assert_equal
    _('assertion only').must_hold :assert_equal
    # 3. Only Message
    assert_hold 'message only', 'msg'
    _('message only').must_hold 'msg'
    # 4. Assertion + Message
    assert_hold 'assertion first', :assert_equal, 'msg'
    _('assertion first').must_hold :assert_equal, 'msg'
    # 5. Message + Assertion
    assert_hold 'message first', 'msg', :assert_equal
    _('message first').must_hold 'msg', :assert_equal
    # 11. Proc Message
    assert_hold 'proc message', proc { 'lazy msg' }
    _('proc message').must_hold proc { 'lazy msg' }
    # 12. Proc Message + Assertion
    assert_hold 'proc msg first', proc { 'lazy msg' }, :assert_equal
    _('proc msg first').must_hold proc { 'lazy msg' }, :assert_equal
    # 13. Assertion + Proc Message
    assert_hold 'proc msg last', :assert_equal, proc { 'lazy msg' }
    _('proc msg last').must_hold :assert_equal, proc { 'lazy msg' }
  end

  it 'should fail' do
    # the store contains 'right_value' instead of 'wrong_value' (edit manually if this test fails)
    error = assert_raises(Minitest::Assertion) do
      _('wrong_value').must_hold
    end
    _(error.message).must_equal "Expected: \"right_value\"\n  Actual: \"wrong_value\""
    error2 = assert_raises(Minitest::Assertion) do
      assert_hold 'wrong_value'
    end
    _(error2.message).must_equal "Expected: \"right_value\"\n  Actual: \"wrong_value\""

    # Prevent saving the wrong values used for testing failure
    @hold.instance_variable_get(:@session).clear
  end

  it 'should force holdify' do
    assert_hold!('store-holdify (right_value)')
    _(@hold.forced).wont_be_empty
    _('store-holdify (right_value)').must_hold!
    _(@hold.forced).wont_be_empty

    @hold.forced.clear
  end
end
