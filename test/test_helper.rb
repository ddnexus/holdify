# frozen_string_literal: true

require 'simplecov' if ENV['COVERAGE']

$LOAD_PATH.unshift __dir__
$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require 'minitest'
require 'minitest/spec'
require 'minitest/mock'
Minitest.load :holdify

require 'fileutils'
require 'helpers/minitest_backtraces'
require 'helpers/key_helper'

require 'minitest/autorun'
