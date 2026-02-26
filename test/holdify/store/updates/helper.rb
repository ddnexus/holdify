# frozen_string_literal: true

require_relative '../../../test_helper'
require 'yaml'

module UpdateHelper
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def watch(test_path)
      after_change_path = test_path.sub('.rb', '_after_change.rb.yaml')

      # Setup backup and verification
      before do
        store_path       = "#{test_path}#{Holdify.store_ext}"
        @_store_path     = store_path
        @_original_data  = File.exist?(store_path) ? File.read(store_path) : nil
        @_original_mtime = File.exist?(store_path) ? File.mtime(store_path) : nil
      end

      after do
        store_path = "#{test_path}#{Holdify.store_ext}"
        Holdify.stores(test_path).persist

        begin
          # 1. VERIFY
          _(File.exist?(after_change_path)).must_equal true, "Missing expectation file: #{after_change_path}"
          _(File.exist?(store_path)).must_equal true, 'Store file must exist'

          actual_store       = YAML.unsafe_load_file(store_path)
          after_change_store = YAML.unsafe_load_file(after_change_path)

          _(actual_store).must_equal after_change_store
        ensure
          # 2. RESTORE
          if @_original_data
            File.write(store_path, @_original_data)
            File.utime(@_original_mtime, @_original_mtime, store_path) if @_original_mtime
          else
            FileUtils.rm_f(store_path)
          end
          Holdify.stores.delete(test_path)
        end
      end
    end
  end
end
