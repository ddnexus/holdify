# frozen_string_literal: true

require 'test_helper'
require 'holdify/pretty'

describe Holdify::Pretty do
  let(:git_available?) { system('git --version', out: File::NULL, err: File::NULL) }

  it 'generates a diff with colors' do
    skip 'git not available' unless git_available?

    diff = Holdify::Pretty.call('foo', 'bar')

    _(diff).wont_be_nil
    _(diff).must_match(/\e\[/) # ANSI escape code
    _(diff).must_match(/Expected/)
    _(diff).must_match(/Actual/)
    _(diff).must_match(/foo/)
    _(diff).must_match(/bar/)
  end

  it 'handles complex objects' do
    skip 'git not available' unless git_available?

    diff = Holdify::Pretty.call({ 'a' => 1 }, { 'a' => 2 })

    _(diff).must_match(/a:/)
    _(diff).must_match(/1/)
    _(diff).must_match(/2/)
  end

  it 'returns nil if git command fails' do
    Open3.stub :capture3, ->(*) { raise Errno::ENOENT } do
      assert_nil Holdify::Pretty.call('a', 'b')
    end
  end

  it 'handles cleanup when first file creation fails' do
    Tempfile.stub :new, ->(*) { raise 'fail' } do
      assert_raises(RuntimeError) { Holdify::Pretty.call('a', 'b') }
    end
  end

  it 'handles cleanup when second file creation fails' do
    # Use a simple fake instead of a strict Mock to allow methods like #tap to work
    # rubocop:disable Style/SingleLineMethods
    fake_file = Struct.new(:closed) do
      def write(*); end
      def flush; end
      def close!; self.closed = true; end
      def path; 'fake'; end
    end.new
    # rubocop:enable Style/SingleLineMethods

    count = 0
    stubbed_new = lambda do |*|
      count += 1
      raise 'fail' if count > 1

      fake_file
    end

    Tempfile.stub :new, stubbed_new do
      assert_raises(RuntimeError) { Holdify::Pretty.call('a', 'b') }
    end
    assert fake_file.closed
  end

  it 'returns nil for identical objects' do
    skip 'git not available' unless git_available?

    assert_nil Holdify::Pretty.call('same', 'same')
  end

  it 'returns nil for malformed git output' do
    Open3.stub :capture3, ['not a diff', '', 0] do
      assert_nil Holdify::Pretty.call('a', 'b')
    end
  end

  it 'handles context words' do
    skip 'git not available' unless git_available?

    diff = Holdify::Pretty.call(%w[context old], %w[context new])
    _(diff).must_match(/#{Regexp.escape(Holdify::Pretty::G_BASE)}- context/o)
  end

  it 'flushes remaining buffers if no newline token' do
    Open3.stub :capture3, ["@@ -1 +1 @@\n-old\n+new", '', 0] do
      diff = Holdify::Pretty.call('a', 'b')
      _(diff).must_match(/old/)
      _(diff).must_match(/new/)
    end
  end
end
