# frozen_string_literal: true

require 'simplecov' unless ENV['SKIP_COVERAGE']

$LOAD_PATH.unshift __dir__
$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require 'minitest'
require 'minitest/spec'
Minitest.load :holdify

require 'helpers/minitest_backtraces'
require 'minitest/autorun'
