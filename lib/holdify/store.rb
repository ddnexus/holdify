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

      @data  = (File.exist?(@path) && YAML.unsafe_load_file(@path)) || {} # { key => [values] }
      @index = {} # { id => "L123 id" }

      valid_ids = @source.values
      @data.keep_if do |key, _|
        id = key.split.last
        next false unless valid_ids.include?(id)

        @index[id] = key
        true
      end
    end

    def id_at(lineno) = @source[lineno]
    def stored(id)    = @data[@index[id]]

    # Overwrite the entry for a given ID with a new list of values
    def update(id, values)
      new_key = "L#{@source.key(id)} #{id}"
      old_key = @index[id]
      @data.delete(old_key) if old_key && old_key != new_key
      @data[@index[id] = new_key] = values
    end

    def save
      return FileUtils.rm_f(@path) if @data.empty?

      sorted  = @data.sort_by { |k, _| k[/\d+/].to_i }.to_h
      content = YAML.dump(sorted, line_width: -1)
      return if File.exist?(@path) && File.read(@path) == content

      File.write(@path, content)
    end
  end
end
