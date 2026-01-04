# frozen_string_literal: true

require 'test_helper'

describe 'holdify' do
  describe 'Version match' do
    it 'has version' do
      _(Holdify::VERSION).wont_be_nil
    end

    it 'defines the same version in CHANGELOG.md' do
      _(File.read('CHANGELOG.md')).must_match "## Version #{Holdify::VERSION}"
    end
  end

  describe 'Configuration' do
    it 'respects quiet mode' do
      Holdify.quiet = true
      hold = Holdify::Hold.new(self)
      hold.call('quiet_val')
      assert_silent { hold.save }

      Holdify.quiet = false
      hold.call('quiet_val_false')
      _, err = capture_io { hold.save }
      _(err).must_match(/\[holdify\] Held new value/)
    ensure
      Holdify.quiet = false
      path = File.expand_path(__FILE__)
      FileUtils.rm_f("#{path}#{Holdify::CONFIG[:ext]}")
      Holdify.stores.delete(path)
    end
  end
end
