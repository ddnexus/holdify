# frozen_string_literal: true

require 'test_helper'
require 'helpers/external_helper'

class ExternalHelperTest < Minitest::Test
  include ExternalHelper

  def test_external_helper
    assert_hold_external('external')
  end
end
