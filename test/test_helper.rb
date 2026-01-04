# frozen_string_literal: true

require 'simplecov' unless ENV['SKIP_COVERAGE']

$LOAD_PATH.unshift __dir__
$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require 'minitest'
Minitest.parallel_executor = Minitest::Parallel::Executor.new(0)

require 'minitest/spec'
Minitest.load :holdify

require 'fileutils'
require 'helpers/minitest_backtraces'
require 'helpers/key_helper'

require 'minitest/autorun'
