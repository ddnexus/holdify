# frozen_string_literal: true

require 'test_helper'
require 'yaml'

describe 'Holdify Assertions' do
  let(:store_path) { "#{File.expand_path(__FILE__)}#{Holdify::CONFIG[:ext]}" }

  before do
    Holdify.quiet = false
    Holdify.stores.delete(File.expand_path(__FILE__))
    Holdify.stores.delete(__FILE__)
    @hold = Holdify::Hold.new(self)
  end

  after do
    FileUtils.rm_f(store_path)
  end

  it 'handles nil values' do
    assert_hold nil
    @hold.save
    key = last_key

    content = YAML.load_file(store_path)
    _(content[key]).must_equal [nil]
  end

  it 'handles block coverage' do
    tap do
      assert_hold 'block_val'
    end
    @hold.save
    key = last_key

    content = YAML.load_file(store_path)
    _(content[key]).must_equal ['block_val']
  end

  it 'handles multiple assertions' do
    assert_hold 'a'
    key_a = last_key
    assert_hold 'b'
    key_b = last_key
    @hold.save

    content = YAML.load_file(store_path)
    _(content[key_a]).must_equal ['a']
    _(content[key_b]).must_equal ['b']
  end

  it 'handles missing assertion in source' do
    _r = Holdify::Hold.new(self)
    # rubocop:disable Style/EvalWithLocation
    error = assert_raises(RuntimeError) { eval("_r.call('foo')", binding, __FILE__, 10_000) }
    # rubocop:enable Style/EvalWithLocation
    assert_match(/Could not find holdify statement at line 10000/, error.message)
  end
end
