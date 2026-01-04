# frozen_string_literal: true

require_relative 'helper'

describe 'holdify/update/orphan_entry' do
  include UpdateHelper

  watch __FILE__

  it 'removes missing target' do
    assert_hold 'anchor_top'
    assert_hold 'anchor_bottom'
  end
end
