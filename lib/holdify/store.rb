# frozen_string_literal: true

require 'yaml'
require 'fileutils'
require 'digest/sha1'

module Holdify
  # A simple Hash-based store that syncs with a static source map
  class Store
    def initialize(source_path)
      @path = "#{source_path}#{CONFIG[:ext]}"
      File.delete(@path) if Holdify.reconcile && File.exist?(@path)

      @source = {} # { lineno => id }
      File.foreach(source_path).with_index(1) do |line, lineno|
        content = line.strip
        @source[lineno] = Digest::SHA1.hexdigest(content) unless content.empty?
      end

      @index = Hash.new { |h, k| h[k] = [] }                              # { id => ["L123 id", "L124 id"] }
      @data  = (File.exist?(@path) && YAML.unsafe_load_file(@path)) || {} # { key => [values] }

      organize_data
    end

    def id_at(lineno)     = @source[lineno]
    def stored(id, index) = @data[@index[id][index]]

    # Overwrite the entry for a given ID with a new list of values
    def update(lineno, id, values, index)
      new_key = "L#{lineno} #{id}"
      old_key = @index[id][index]
      @data.delete(old_key) if old_key && old_key != new_key
      @data[new_key] = values
      @index[id][index] = new_key
    end

    def save
      return FileUtils.rm_f(@path) if @data.empty?

      sorted  = @data.sort_by { |k, _| k[/\d+/].to_i }.to_h
      content = YAML.dump(sorted, line_width: 78)
      return if File.exist?(@path) && File.read(@path) == content

      File.write(@path, content)
    end

    private

    def organize_data
      source_counts = @source.values.tally
      sorted_keys   = @data.keys.sort_by { |k| k[/\d+/].to_i }

      sorted_keys.each do |key|
        id = key.split.last
        next unless source_counts[id]

        if @index[id].size < source_counts[id]
          @index[id] << key
        else
          @data.delete(key)
        end
      end

      @data.keep_if { |key, _| source_counts[key.split.last] }
    end
  end
end
