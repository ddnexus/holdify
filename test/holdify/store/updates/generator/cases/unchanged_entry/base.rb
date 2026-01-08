# frozen_string_literal: true

require_relative 'helper'

describe 'holdify/update/unchanged_entry' do
  include UpdateHelper

  watch __FILE__

  it 'keeps all entries unchanged' do
    assert_hold 'anchor_top'
    assert_hold 'target_val'
    assert_hold 'anchor_bottom'
  end
end
