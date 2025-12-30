# frozen_string_literal: true

require_relative 'helper'

describe 'holdify/update/new_entry' do
  include UpdateHelper

  watch __FILE__

  it 'inserts new target between anchors' do
    assert_hold 'anchor_top'
    expect('new_target').to_hold
    assert_hold 'anchor_bottom'
  end
end
