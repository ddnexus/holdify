# frozen_string_literal: true

require_relative 'helper'

describe 'holdify/update/moved_entry' do
  include UpdateHelper

  watch __FILE__

  it 'updates moved target and shifts bottom' do
    assert_hold 'anchor_top'
    # Filler to force line number change relative to start store

    expect('moved_target').to_hold
    assert_hold 'anchor_bottom'
  end
end
