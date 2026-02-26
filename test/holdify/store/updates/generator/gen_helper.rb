# frozen_string_literal: true

require 'test_helper'

# This helper is injected into the generator cases to replace the real UpdateHelper.
# Its only job is to ensure a clean run so Holdify generates the store file.
module UpdateHelper
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def watch(path)
      # Ensure we start fresh for the generation run
      store_path = "#{path}#{Holdify.store_ext}"
      FileUtils.rm_f(store_path)
    end
  end
end
