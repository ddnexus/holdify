# frozen_string_literal: true

require 'test_helper'
require 'yaml'

describe 'Holdify::Store Specs' do
  let(:store_path) { "#{File.expand_path(__FILE__)}#{Holdify.store_ext}" }

  def reset_holdify_state
    Holdify.stores.delete(File.expand_path(__FILE__))
    Holdify.stores.delete(__FILE__)
    @hold = Holdify::Hold.new(self)
  end

  before do
    @original_config = Holdify.git_diff
    Holdify.git_diff = false
    FileUtils.rm_f(store_path)
    reset_holdify_state
  end

  after do
    FileUtils.rm_f(store_path)
    Holdify.stores.delete(File.expand_path(__FILE__))
    Holdify.instance_variable_get(:@fresh)&.clear
    Holdify.git_diff = @original_config
  end

  it 'creates the store and the entry' do
    expect('a new value').to_hold
    @hold.save
    Holdify.quiet = false
    _, err = capture_io { Holdify.warn_fresh_values }
    Holdify.quiet = true

    Holdify.stores(File.expand_path(__FILE__)).persist
    key = last_key
    _(err).must_match(/\[HOLDIFY\] Fresh value held for/)

    _(File.exist?(store_path)).must_equal true
    content = YAML.unsafe_load_file(store_path)
    _(content[key]).must_equal ['a new value']
  end

  it 'returns nil when querying a line number not in source' do
    store = Holdify::Store.new(File.expand_path(__FILE__))
    _(store.get_values(10_000)).must_be_nil
  end

  it 'skips saving entries for lines not present in source' do
    store = Holdify::Store.new(File.expand_path(__FILE__))
    store.set_values(10_000, ['phantom'])
    store.persist

    content = YAML.unsafe_load_file(store_path)
    _(content).must_be_empty
  end

  it 'handles empty store deletion' do
    File.write(store_path, "---\n")
    store = Holdify::Store.new(File.expand_path(__FILE__))
    store.persist
    _(File.exist?(store_path)).must_equal false
  end

  it 'handles reconcile deletion in initialize' do
    Holdify.reconcile = true
    File.write(store_path, "---")

    reset_holdify_state

    _(File.exist?(store_path)).must_equal false
  ensure
    Holdify.reconcile = false
  end

  it 'prunes extra identical entries from yaml' do
    # Simulate a source file with 1 occurrence of "content"
    source_file = 'test_prune.rb'
    File.write(source_file, "content\n")
    xxh = Digest::XXH3_64bits.hexdigest('content')

    # Simulate a YAML with 2 entries for that id (as if it previously had 2 lines)
    yaml_path = "#{source_file}#{Holdify.store_ext}"
    data = {
      "L1-#{xxh}" => ['val1'],
      "L2-#{xxh}" => ['val2']
    }
    File.write(yaml_path, YAML.dump(data))

    # Initialize store (triggers organize_data)
    store = Holdify::Store.new(source_file)
    store.persist

    # Verify L2 was removed because source only has 1 occurrence
    saved_data = YAML.unsafe_load_file(yaml_path)
    _(saved_data.size).must_equal 1
    _(saved_data.keys.first).must_equal "L1-#{xxh}"
  ensure
    FileUtils.rm_f(source_file)
    FileUtils.rm_f(yaml_path)
  end

  it 'prunes orphaned entries from yaml' do
    source_file = 'test_orphan.rb'
    yaml_path   = "#{source_file}#{Holdify.store_ext}"

    # 1. Create initial source and store with two entries
    File.write(source_file, "assert_hold 'line 1'\nassert_hold 'line 2 orphan'\n")
    store = Holdify::Store.new(source_file)
    store.set_values(1, ['val1'])
    store.set_values(2, ['val2'])
    store.persist

    # 2. Modify source file, orphaning the second entry
    File.write(source_file, "assert_hold 'line 1'\n")

    # 3. Re-initialize store, which should trigger load_and_align and prune the orphan
    Holdify::Store.new(source_file).persist

    # 4. Verify that the orphaned entry was pruned from the store file
    assert_equal 1, YAML.unsafe_load_file(yaml_path).size
  ensure
    FileUtils.rm_f(source_file) if source_file
    FileUtils.rm_f(yaml_path) if yaml_path
  end
end
