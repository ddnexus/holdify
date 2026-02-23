# frozen_string_literal: true

require 'test_helper'
require 'yaml'

describe 'Holdify::Store Specs' do
  let(:store_path) { "#{File.expand_path(__FILE__)}#{Holdify::CONFIG[:ext]}" }

  def reset_holdify_state
    Holdify.stores.delete(File.expand_path(__FILE__))
    Holdify.stores.delete(__FILE__)
    @hold = Holdify::Hold.new(self)
  end

  before do
    Holdify.quiet = false
    Holdify.config[:git] = false
    FileUtils.rm_f(store_path)
    reset_holdify_state
  end

  after do
    FileUtils.rm_f(store_path)
    Holdify.stores.delete(File.expand_path(__FILE__))
  end

  it 'creates the store and the entry' do
    _, err = capture_io do
      expect('a new value').to_hold
      @hold.save
    end
    Holdify.stores(File.expand_path(__FILE__)).persist
    key = last_key
    _(err).must_match(/\[holdify\] Held new value for .*store_test.rb/)

    _(File.exist?(store_path)).must_equal true
    content = YAML.load_file(store_path)
    _(content[key]).must_equal ['a new value']
  end

  it 'verifies existing entries on second run' do
    # We use a loop to ensure the exact same line number is used for the assertion,
    # simulating multiple runs of the same test code.
    [0, 1, 2].each do |step|
      val = step == 2 ? 'wrong value' : 'persistent value'

      reset_holdify_state if step.positive?

      begin
        out, err = capture_io { expect(val).to_hold }

        if step.zero?
          @hold.save
          Holdify.stores(File.expand_path(__FILE__)).persist
        end

        if step == 1
          _(out).must_be_empty
          _(err).must_be_empty
        end
      rescue Minitest::Assertion => e
        raise e unless step == 2

        _(e.message).must_match(/Expected: "persistent value"/)
      end
    end
  end

  it 'returns nil when querying a line number not in source' do
    store = Holdify::Store.new(File.expand_path(__FILE__))
    _(store.get(10_000)).must_be_nil
  end

  it 'skips saving entries for lines not present in source' do
    store = Holdify::Store.new(File.expand_path(__FILE__))
    store.set(10_000, ['phantom'])
    store.persist

    content = YAML.load_file(store_path)
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
    yaml_path = "#{source_file}#{Holdify::CONFIG[:ext]}"
    data = {
      "L1 #{xxh}" => ['val1'],
      "L2 #{xxh}" => ['val2']
    }
    File.write(yaml_path, YAML.dump(data))

    # Initialize store (triggers organize_data)
    store = Holdify::Store.new(source_file)
    store.persist

    # Verify L2 was removed because source only has 1 occurrence
    saved_data = YAML.load_file(yaml_path)
    _(saved_data.size).must_equal 1
    _(saved_data.keys.first).must_equal "L1 #{xxh}"
  ensure
    FileUtils.rm_f(source_file)
    FileUtils.rm_f(yaml_path)
  end
end
