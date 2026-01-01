# frozen_string_literal: true

require 'test_helper'
require 'optparse'

describe 'Holdify Coverage' do
  after do
    Holdify.reconcile = false
    Holdify.quiet = false
  end

  it 'handles nil values' do
    # Covers minitest/holder_plugin.rb: if actual.nil?
    assert_hold nil
    _(nil).must_hold
  end

  it 'handles empty store deletion' do
    # Covers holdify/store.rb: return FileUtils.rm_f(@path) if @entries.empty?
    path = "#{__FILE__}.yaml"
    File.write(path, "---\n")
    store = Holdify::Store.new(__FILE__)
    store.save
    _(File.exist?(path)).must_equal false
  end

  it 'handles reconcile option parsing' do
    # Covers minitest/holder_plugin.rb: opts.on '--holdify-reconcile'
    opts = OptionParser.new
    Minitest.plugin_holdify_options(opts, {})
    opts.parse!(['--holdify-reconcile'])
    _(Holdify.reconcile).must_equal true
  end

  it 'handles reconcile deletion in initialize' do
    # Covers holdify.rb: File.delete(path) if self.class.reconcile
    Holdify.reconcile = true
    store_path = "#{__FILE__}#{Holdify::CONFIG[:ext]}"
    File.write(store_path, "---")

    # Clear cache to force re-initialization
    Holdify.stores.delete(__FILE__)

    # Initialize should trigger deletion
    Holdify.new(self)
    _(File.exist?(store_path)).must_equal false
  end
end
