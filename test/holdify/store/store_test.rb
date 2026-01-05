# frozen_string_literal: true

require 'test_helper'
require 'yaml'

describe 'Holdify::Store' do
  let(:store_path) { "#{File.expand_path(__FILE__)}#{Holdify::CONFIG[:ext]}" }

  def reset_holdify_state
    Holdify.stores.delete(File.expand_path(__FILE__))
    Holdify.stores.delete(__FILE__)
    @hold = Holdify::Hold.new(self)
  end

  before do
    Holdify.quiet = false
    Holdify.pretty = false
    FileUtils.rm_f(store_path)
    reset_holdify_state
  end

  after do
    FileUtils.rm_f(store_path)
  end

  it 'creates the store and the entry' do
    _, err = capture_io do
      expect('a new value').to_hold
      @hold.save
    end
    key = last_key
    _(err).must_match(/\[holdify\] Held new value for .*store_test.rb/)

    _(File.exist?(store_path)).must_equal true
    content = YAML.load_file(store_path)
    _(content[key]).must_equal ['a new value']
  end

  it 'verifies existing entries on second run' do
    val = 'persistent value'

    # 1. First run: Create
    expect(val).to_hold
    @hold.save

    # 2. Reset memory state to simulate new run
    reset_holdify_state

    # 3. Second run: Verify (should pass)
    assert_silent do
      expect(val).to_hold
    end

    # Reset memory state again to ensure the entry is available for the next assertion
    reset_holdify_state

    # 4. Verify mismatch
    val = 'wrong value'
    error = assert_raises(Minitest::Assertion) do
      expect(val).to_hold
    end
    _(error.message).must_match(/Expected: "persistent value"/)
  end

  it 'handles empty store deletion' do
    File.write(store_path, "---\n")
    store = Holdify::Store.new(File.expand_path(__FILE__))
    store.save
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
    sha = Digest::SHA1.hexdigest('content')

    # Simulate a YAML with 2 entries for that SHA (as if it previously had 2 lines)
    yaml_path = "#{source_file}#{Holdify::CONFIG[:ext]}"
    data = {
      "L1 #{sha}" => ['val1'],
      "L2 #{sha}" => ['val2']
    }
    File.write(yaml_path, YAML.dump(data))

    # Initialize store (triggers organize_data)
    store = Holdify::Store.new(source_file)
    store.save

    # Verify L2 was removed because source only has 1 occurrence
    saved_data = YAML.load_file(yaml_path)
    _(saved_data.size).must_equal 1
    _(saved_data.keys.first).must_equal "L1 #{sha}"
  ensure
    FileUtils.rm_f(source_file)
    FileUtils.rm_f(yaml_path)
  end
end
