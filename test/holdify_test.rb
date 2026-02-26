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
      FileUtils.rm_f("#{path}#{Holdify.store_ext}")
      Holdify.stores.delete(path)
    end

    it 'respects relative_paths config' do
      Holdify.rel_paths = false
      path = '/some/absolute/path/file.rb'
      _(Holdify.relative(path)).must_equal path
    ensure
      Holdify.rel_paths = true
    end
  end

  describe 'persist_all!' do
    it 'handles nil stores' do
      stores = Holdify.instance_variable_get(:@stores)
      Holdify.instance_variable_set(:@stores, nil)
      assert_nil Holdify.persist_all!
    ensure
      Holdify.instance_variable_set(:@stores, stores)
    end

    it 'persists stores' do
      path = File.expand_path(__FILE__)
      store_path = "#{path}#{Holdify.store_ext}"

      # This will create a store and add it to Holdify.stores
      assert_hold 'data for persist_all'
      @hold.save # This will put the data into the store object

      # Now call persist_all!
      Holdify.persist_all!

      # Verify the file was written
      assert_path_exists store_path
      content = YAML.load_file(store_path)
      assert_includes content.values.flatten, 'data for persist_all'
    ensure
      FileUtils.rm_f(store_path) if store_path
      Holdify.stores.delete(path) if path
    end
  end
end
