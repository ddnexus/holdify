# frozen_string_literal: true

# rubocop:disable Layout/TrailingWhitespace, Style/RedundantStringEscape
require 'test_helper'

# add lines for future adjustment
SEP = RUBY_VERSION.match?(/\A3\.[23]/) ? '=>' : ' => '
describe 'Holdify::Feedback Specs' do
  let(:val) do
    if File.exist?("#{File.expand_path(__FILE__)}#{Holdify.store_ext}")
      [
        'common line',
        'changed line old',
        { 'remove' => 'remove',
          'key'    => 'val' }
      ]
    else
      [
        'common line',
        'changed line new',
        { 'key' => 'val',
          'add' => 'add' }
      ]
    end
  end

  def with_config(**config)
    original_config  = [Holdify.git_diff, Holdify.color]
    Holdify.git_diff = config[:git]
    Holdify.color    = config[:color]
    yield
  ensure
    Holdify.git_diff, Holdify.color = original_config
  end

  def external_helper(value)
    assert_hold value, 'Custom message with hold and test path'
  end

  describe 'Output formats' do
    it 'generates git colored diff' do
      with_config(git: true, color: true) do
        assert_hold val
      end
    rescue Minitest::Assertion => e
      assert_equal <<~EXP, e.message

        \e[35m<<< @xxh[i] --> 6a431ee396381dd4[0]\e[0m
        \e[31m--- @stored --> test/holdify/feedback/feedback_test.rb.yaml:3\e[0m
        \e[32m+++ @tested --> test/holdify/feedback/feedback_test.rb:43\e[0m
        \e[36m@@ -1,4 +1,4 @@\e[m
         3\e[0m - common line\e[m
        \e[33m~4\e[0m - changed line \e[31mnew\e[m\e[32mold\e[m
        \e[33m~5\e[0m - \e[31mkey:\e[m\e[32mremove:\e[m \e[31mval\e[m\e[32mremove\e[m
        \e[33m~6\e[0m   \e[31madd:\e[m\e[32mkey:\e[m \e[31madd\e[m\e[32mval\e[m
      EXP
    end

    it 'generates git no-color diff' do
      with_config(git: true, color: false) do
        assert_hold val
      end
    rescue Minitest::Assertion => e
      assert_equal <<~EXP, e.message
      
        <<< @xxh[i] --> 6a431ee396381dd4[0]
        --- @stored --> test/holdify/feedback/feedback_test.rb.yaml:8
        +++ @tested --> test/holdify/feedback/feedback_test.rb:61
        @@ -1,4 +1,4 @@
          8 - common line
        - 9 - changed line new
        -10 - key: val
        -11   add: add
        +   - changed line old
        +   - remove: remove
        +     key: val
      EXP
    end

    it 'generates minitest diff (no git)' do
      with_config(git: false, color: true) do
        assert_hold val
      end
    rescue Minitest::Assertion => e
      assert_equal <<~EXP, e.message

        \e[35m<<< @xxh[i] --> 6a431ee396381dd4[0]\e[0m
        \e[31m--- @stored --> test/holdify/feedback/feedback_test.rb.yaml:13\e[0m
        \e[32m+++ @tested --> test/holdify/feedback/feedback_test.rb:82\e[0m
        \e[31m- [\"common line\", \"changed line new\", {\"key\"#{SEP}\"val\", \"add\"#{SEP}\"add\"}]\e[0m
        \e[32m+ [\"common line\", \"changed line old\", {\"remove\"#{SEP}\"remove\", \"key\"#{SEP}\"val\"}]\e[0m
      EXP
    end

    it 'generates minitest diff with custom message (no git, no color)' do
      with_config(git: false, color: false) do
        external_helper(val)
      end
    rescue Minitest::Assertion => e
      assert_equal <<~EXP, e.message
        Custom message with hold and test path
        <<< @xxh[i] --> 05922e43fb0eae28[0]
        --- @stored --> test/holdify/feedback/feedback_test.rb.yaml:18
        +++ @tested --> test/holdify/feedback/feedback_test.rb:37
                    --> test/holdify/feedback/feedback_test.rb:97
        - [\"common line\", \"changed line new\", {\"key\"#{SEP}\"val\", \"add\"#{SEP}\"add\"}]
        + [\"common line\", \"changed line old\", {\"remove\"#{SEP}\"remove\", \"key\"#{SEP}\"val\"}]
      EXP
    end

    it 'generates feedback' do
      with_config(git: true, color: true) do
        assert_hold val
      end
    rescue Minitest::Assertion => e
      assert_equal <<~EXP, e.message

        \e[35m<<< @xxh[i] --> 6a431ee396381dd4[0]\e[0m
        \e[31m--- @stored --> test/holdify/feedback/feedback_test.rb.yaml:23\e[0m
        \e[32m+++ @tested --> test/holdify/feedback/feedback_test.rb:113\e[0m
        \e[36m@@ -1,4 +1,4 @@\e[m
         23\e[0m - common line\e[m
        \e[33m~24\e[0m - changed line \e[31mnew\e[m\e[32mold\e[m
        \e[33m~25\e[0m - \e[31mkey:\e[m\e[32mremove:\e[m \e[31mval\e[m\e[32mremove\e[m
        \e[33m~26\e[0m   \e[31madd:\e[m\e[32mkey:\e[m \e[31madd\e[m\e[32mval\e[m
      EXP
    end
  end
end
# rubocop:enable Layout/TrailingWhitespace, Style/RedundantStringEscape
