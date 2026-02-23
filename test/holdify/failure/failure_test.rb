# frozen_string_literal: true

require 'test_helper'
require 'holdify/failure'
require 'minitest/mock'

describe 'Holdify::Failure Specs' do
  before do
    @expected = { a: 1, b: 2 }
    @actual = { a: 1, b: 3 }
    @message = 'Failure message'
    @location = Minitest::Mock.new
    @location.expect(:path, '/path/to/test.rb')
    @location.expect(:lineno, 10)
    @metadata = { path: '/path/to/expected.yaml', line: 5, key: 'test_key' }

    @default_config = { git: false, color: false }
    Holdify.stub :config, @default_config do
      @failure = Holdify::Failure.new(@expected, @actual, @message, location: @location, metadata: @metadata)
    end
  end

  after do
    @location.verify
  end

  describe '#initialize' do
    before do
      # The outer before block sets expectations on @location that are not met by the initialize test.
      # We create a new mock for @location without expectations for this context.
      @location = Minitest::Mock.new
      @failure = Holdify::Failure.new(@expected, @actual, @message, location: @location, metadata: @metadata)
    end

    it 'sets instance variables correctly' do
      _(@failure.instance_variable_get(:@expected)).must_equal @expected
      _(@failure.instance_variable_get(:@actual)).must_equal @actual
      _(@failure.instance_variable_get(:@message)).must_equal @message
    end
  end

  describe '#message' do
    it 'returns the message when git is disabled' do
      Holdify.stub :config, { git: false, color: false } do
        failure = Holdify::Failure.new(@expected, @actual, @message, location: @location, metadata: @metadata)
        _(failure.message).must_equal "--- @yaml >>> /path/to/expected.yaml:5\n+++ @test >>> /path/to/test.rb:10\n<-- test_key \nFailure message"
      end
    end

    it 'returns a colored message when git is disabled and color is enabled' do
      Holdify.stub :config, { git: false, color: true } do
        failure = Holdify::Failure.new(@expected, @actual, @message, location: @location, metadata: @metadata)
        expected_message = "\e[31m--- @yaml\e[0m >>> /path/to/expected.yaml:5\n\e[32m+++ @test\e[0m >>> /path/to/test.rb:10\n\e[7m<-- test_key \e[0m\nFailure message"
        _(failure.message).must_equal expected_message
      end
    end

    it 'returns a diff when git is enabled' do
      # Mock Open3.capture3 to return a dummy diff output
      # Note: The current implementation of Failure#diff_lines does not strip these headers
      # because the regex expects a specific format. We test the current behavior.
      diff_output = "--- a/file1\n+++ b/file2\n@@ -1,2 +1,2 @@\n-a: 1\n+a: 3\n"
      Open3.stub :capture3, [diff_output, "", 0] do
        Holdify.stub :config, { git: true, color: false } do
          failure = Holdify::Failure.new(@expected, @actual, @message, location: @location, metadata: @metadata)
          expected_message = "--- @yaml >>> /path/to/expected.yaml:5\n+++ @test >>> /path/to/test.rb:10\n<-- test_key \n  5 - -- a/file1\n    + ++ b/file2\n  6 @ @ -1,2 +1,2 @@\n  7 - a: 1\n    + a: 3"
          _(failure.message).must_equal expected_message
        end
      end
    end

    it 'returns a colored diff when git and color are enabled' do
      # Mock Open3.capture3 to return a dummy colored diff output
      colored_diff_output = "--- a/file1\n+++ b/file2\n@@ -1,2 +1,2 @@\n\e[31m-a: 1\e[0m\n\e[32m+a: 3\e[0m\n"
      Open3.stub :capture3, [colored_diff_output, "", 0] do
        Holdify.stub :config, { git: true, color: true } do
          failure = Holdify::Failure.new(@expected, @actual, @message, location: @location, metadata: @metadata)
          # Based on current implementation which includes headers and calculates gutters
          expected_message = "\e[31m--- @yaml\e[0m >>> /path/to/expected.yaml:5\n\e[32m+++ @test\e[0m >>> /path/to/test.rb:10\n\e[7m<-- test_key \e[0m\n\e[7m  5\e[0m --- a/file1\n\e[7m  6\e[0m +++ b/file2\n\e[7m  7\e[0m @@ -1,2 +1,2 @@\n\e[7m  8\e[0m \e[31m-a: 1\e[0m\n\e[7m   \e[0m \e[32m+a: 3\e[0m"
          _(failure.message).must_equal expected_message
        end
      end
    end

    it 'handles empty diff output gracefully' do
      Open3.stub :capture3, ["", "", 0] do
        Holdify.stub :config, { git: true, color: false } do
          failure = Holdify::Failure.new(@expected, @actual, @message, location: @location, metadata: @metadata)
          expected_message = "--- @yaml >>> /path/to/expected.yaml:5\n+++ @test >>> /path/to/test.rb:10\n<-- test_key "
          _(failure.message).must_equal expected_message
        end
      end
    end
  end

  describe '#add_headers' do
    it 'returns correct headers without color' do
      Holdify.stub :config, { git: false, color: false } do
        failure = Holdify::Failure.new(@expected, @actual, @message, location: @location, metadata: @metadata)
        expected_headers = [
          "--- @yaml >>> /path/to/expected.yaml:5",
          "+++ @test >>> /path/to/test.rb:10",
          "<-- test_key "
        ]
        _(failure.add_headers).must_equal expected_headers
      end
    end

    it 'returns correct headers with color' do
      Holdify.stub :config, { git: false, color: true } do
        failure = Holdify::Failure.new(@expected, @actual, @message, location: @location, metadata: @metadata)
        expected_headers = [
          "\e[31m--- @yaml\e[0m >>> /path/to/expected.yaml:5",
          "\e[32m+++ @test\e[0m >>> /path/to/test.rb:10",
          "\e[7m<-- test_key \e[0m"
        ]
        _(failure.add_headers).must_equal expected_headers
      end
    end
  end

  describe '#ansi' do
    before do
      @location = Minitest::Mock.new
      @failure = Holdify::Failure.new(@expected, @actual, @message, location: @location, metadata: @metadata)
    end

    it 'returns empty hash when color is disabled' do
      Holdify.stub :config, { git: false, color: false } do
        failure = Holdify::Failure.new(@expected, @actual, @message, location: @location, metadata: @metadata)
        _(failure.ansi).must_equal({})
      end
    end

    it 'returns ansi codes when color is enabled' do
      Holdify.stub :config, { git: false, color: true } do
        failure = Holdify::Failure.new(@expected, @actual, @message, location: @location, metadata: @metadata)
        expected_ansi_codes = { inverse: "\e[7m", reset: "\e[0m", red: "\e[31m", green: "\e[32m" }
        _(failure.ansi).must_equal expected_ansi_codes
      end
    end
  end

  describe '#git_command' do
    before do
      @location = Minitest::Mock.new
      @exp_file_mock = Minitest::Mock.new
      @act_file_mock = Minitest::Mock.new
    end

    after do
      @exp_file_mock.verify
      @act_file_mock.verify
    end

    it 'returns correct git command without color' do
      Holdify.stub :config, { git: true, color: false } do
        failure_with_git = Holdify::Failure.new(@expected, @actual, @message, location: @location, metadata: @metadata)
        @exp_file_mock.expect(:path, '/tmp/expected_file.yaml')
        @act_file_mock.expect(:path, '/tmp/actual_file.yaml')
        failure_with_git.instance_variable_set(:@exp_file, @exp_file_mock)
        failure_with_git.instance_variable_set(:@act_file, @act_file_mock)
        expected_command = %w[git diff --no-index --no-color --unified=1000 /tmp/expected_file.yaml /tmp/actual_file.yaml]
        _(failure_with_git.git_command).must_equal expected_command
      end
    end

    it 'returns correct git command with color' do
      Holdify.stub :config, { git: true, color: true } do
        failure_with_git = Holdify::Failure.new(@expected, @actual, @message, location: @location, metadata: @metadata)
        @exp_file_mock.expect(:path, '/tmp/expected_file.yaml')
        @act_file_mock.expect(:path, '/tmp/actual_file.yaml')
        failure_with_git.instance_variable_set(:@exp_file, @exp_file_mock)
        failure_with_git.instance_variable_set(:@act_file, @act_file_mock)
        regex = '[^[:space:]]+|[[:space:]]+'
        expected_command = ["git", "diff", "--no-index", "--color-words=#{regex}", "--unified=1000", "/tmp/expected_file.yaml", "/tmp/actual_file.yaml"]
        _(failure_with_git.git_command).must_equal expected_command
      end
    end
  end

  describe '#add_diff' do
    before do
      @location = Minitest::Mock.new
    end

    it 'returns empty array on ENOENT' do
      Holdify.stub :config, { git: true, color: false } do
        failure = Holdify::Failure.new(@expected, @actual, @message, location: @location, metadata: @metadata)
        failure.stub :create_tempfile, ->(_) { raise Errno::ENOENT } do
          _(failure.add_diff).must_equal []
        end
      end
    end

    it 'calls process_lines when color is disabled' do
      Holdify.stub :config, { git: true, color: false } do
        failure = Holdify::Failure.new(@expected, @actual, @message, location: @location, metadata: @metadata)

        mock_file = Minitest::Mock.new
        mock_file.expect(:close!, nil)
        mock_file.expect(:close!, nil)

        failure.stub :create_tempfile, mock_file do
          failure.stub :process_lines, ['diff'] do
            _(failure.add_diff).must_equal ['diff']
          end
        end
        mock_file.verify
      end
    end

    it 'calls color_process_lines when color is enabled' do
      Holdify.stub :config, { git: true, color: true } do
        failure = Holdify::Failure.new(@expected, @actual, @message, location: @location, metadata: @metadata)

        mock_file = Minitest::Mock.new
        mock_file.expect(:close!, nil)
        mock_file.expect(:close!, nil)

        failure.stub :create_tempfile, mock_file do
          failure.stub :color_process_lines, ['colored_diff'] do
            _(failure.add_diff).must_equal ['colored_diff']
          end
        end
        mock_file.verify
      end
    end
  end

  describe '#diff_lines' do
    before do
      @location = Minitest::Mock.new
      @failure = Holdify::Failure.new(@expected, @actual, @message, location: @location, metadata: @metadata)
    end

    it 'returns empty array if stdout is empty' do
      Open3.stub :capture3, ["", "", 0] do
        Holdify.stub :config, { git: true, color: false } do
          # We need to stub git_command because it's called before capture3
          @failure.stub :git_command, [] do
            _(@failure.diff_lines).must_equal []
          end
        end
      end
    end

    it 'returns parsed lines from real git output' do
      raw_output = File.read('test/holdify/failure/git_color_output.bin')
      Open3.stub :capture3, [raw_output, "", 0] do
        Holdify.stub :config, { git: true, color: false } do
          @failure.stub :git_command, [] do
            lines = @failure.diff_lines
            # The first line after stripping the header is "L10 51898a228aead05f:\e[m"
            _(lines.first).must_include "L10 51898a228aead05f"
            _(lines.size).must_be :>, 0
          end
        end
      end
    end
  end

  describe '#color_process_lines' do
    before do
      @location = Minitest::Mock.new
      @failure = Holdify::Failure.new(@expected, @actual, @message, location: @location, metadata: @metadata)
    end

    it 'processes colored lines correctly' do
      # We simulate what diff_lines would return after stripping the header from git_color_output.bin

      lines = [
        "L10 51898a228aead05f:\e[m",
        "- - one\e[m",
        "  - two\e[m",
        "  - three\e[m",
        "L33 653e11aeec38dce2:\e[m",
        "- :app: Holdify\e[m",
        "  :version: \e[31m1.1.1\e[m\e[32m1.0.6\e[m",
        "  :features:\e[m",
        "  - store\e[m",
        "  - pretty_diff\e[m",
        "  :config:\e[m",
        "\e[31m    :adapter: sqlite\e[m",
        "    :pool: 10\e[m",
        "    :timeout: 5000\e[m",
        "\e[32m    :tz: EST\e[m",
        "  :description: Holdify allows you to \e[31measily\e[m\e[32mautomatically\e[m hold objects and compare them in future runs. It \e[31muses\e[m\e[32mrun\e[m git \e[31mfor \e[mdiffs."
      ]

      Holdify.stub :config, { git: true, color: true } do
        @failure.stub :diff_lines, lines do
          processed = @failure.color_process_lines

          # Line 1: L10 ... (unchanged)
          # Gutter should be line number (6)
          _(processed[0]).must_include "5"
          _(processed[0]).must_include "L10 51898a228aead05f"

          # Line 7: :version: ... (changed)
          # Gutter should be line number (12)
          _(processed[6]).must_include "11"
          _(processed[6]).must_include ":version:"

          # Line 12: :adapter: sqlite (removed)
          # This line starts with red text.
          # Gutter should be line number.
          _(processed[11]).must_include ":adapter: sqlite"

          # Line 15: :tz: EST (added)
          # This line starts with green text.
          # Gutter should be empty spaces.
          _(processed[14]).must_include ":tz: EST"
          # Check for empty gutter (3 spaces)
          # The implementation uses ' ' * GUTTER_WIDTH (3)
          # And wraps it in inverse color: "#{ansi[:inverse]}#{gutter}#{ansi[:reset]} #{line}"
          # So we expect "\e[7m   \e[0m"
          _(processed[14]).must_include "\e[7m   \e[0m"
        end
      end
    end
  end

  describe '#process_lines' do
    before do
      @location = Minitest::Mock.new
      @failure = Holdify::Failure.new(@expected, @actual, @message, location: @location, metadata: @metadata)
    end

    it 'processes lines correctly without color' do
      lines = [
        " line1",
        "-line2",
        "+line3",
        " line4"
      ]

      Holdify.stub :config, { git: true, color: false } do
        @failure.stub :diff_lines, lines do
          processed = @failure.process_lines

          # Line 1: " line1" -> type=" ", line="line1"
          # Gutter: 6
          _(processed[0]).must_equal "  5   line1"

          # Line 2: "-line2" -> type="-", line="line2"
          # Gutter: 7
          _(processed[1]).must_equal "  6 - line2"

          # Line 3: "+line3" -> type="+", line="line3"
          # Gutter: empty (3 spaces)
          _(processed[2]).must_equal "    + line3"

          # Line 4: " line4" -> type=" ", line="line4"
          # Gutter: 8
          _(processed[3]).must_equal "  7   line4"
        end
      end
    end
  end

  describe '#create_tempfile' do
    before do
      @location = Minitest::Mock.new
      @failure = Holdify::Failure.new(@expected, @actual, @message, location: @location, metadata: @metadata)
    end

    it 'creates a tempfile with yaml content' do
      tempfile = @failure.create_tempfile({ test: 'data' })
      _(File.exist?(tempfile.path)).must_equal true
      _(File.read(tempfile.path)).must_equal "---\n:test: data\n"
    ensure
      tempfile&.close!
      tempfile&.unlink
    end
  end
end
