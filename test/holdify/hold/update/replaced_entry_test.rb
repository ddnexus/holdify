# frozen_string_literal: true

require_relative 'helper'

describe 'holdify/update/replaced_entry' do
  include UpdateHelper

  watch __FILE__

  it 'updates replaced target value' do
    assert_hold 'anchor_top'
    assert_hold 'new_value'
    assert_hold 'anchor_bottom'
  end
end
