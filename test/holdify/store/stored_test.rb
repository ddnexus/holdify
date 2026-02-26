# frozen_string_literal: true

require 'test_helper'
require 'time'

describe 'holdify/stored' do
  before do
    @original_config = Holdify.git
    Holdify.git = false
  end

  after do
    Holdify.git = @original_config
  end

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

  it 'should force holdify' do
    assert_hold!('store-holdify (right_value)')
    _(@hold.forced).wont_be_empty
    _('store-holdify (right_value)').must_hold!
    _(@hold.forced).wont_be_empty

    @hold.forced.clear
  end

  it 'stores two tween lines in two keys' do
    result = 'val 1'
    assert_hold(result)
    result = 'val 2'
    assert_hold(result)
  end
end
