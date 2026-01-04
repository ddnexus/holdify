# frozen_string_literal: true

require 'test_helper'

class NestedHelperTest < Minitest::Test
  def helper_method(value)
    assert_hold value
  end

  def test_direct_call
    helper_method('direct')
  end

  def test_loop_call
    %w[loop1 loop2].each do |val|
      helper_method(val)
    end
  end

  def test_nested_helper_call
    nested_wrapper('nested')
  end

  def nested_wrapper(val)
    helper_method(val)
  end

  def test_block_call
    2.times { helper_method('block') }
  end

  def test_lambda_call
    -> { helper_method('lambda') }.call
  end

  def test_tap
    tap { helper_method('tap') }
  end

  def test_proc_call
    proc { helper_method('proc') }.call
  end
end
