# frozen_string_literal: true

require 'yaml'
require 'fileutils'

module Holdify
  # Manages the persistence and alignment of stored values
  class Ledger
    def initialize(path, source)
      @path   = "#{path}#{CONFIG[:ext]}"
      @source = source
      File.delete(@path) if Holdify.reconcile && File.exist?(@path)
      @data = load_and_align
    end

    def get(line) = @data[line]

    def set(line, values) = (@data[line] = values)

    def save
      return FileUtils.rm_f(@path) if @data.empty?

      output = {}
      @data.keys.sort.each do |line|
        sha = @source.sha_at(line)
        next unless sha

        output["L#{line} #{sha}"] = @data[line]
      end

      content = YAML.dump(output, line_width: 78) # Ensure 80 columns (including pretty gutter)
      return if File.exist?(@path) && File.read(@path) == content

      File.write(@path, content)
    end

    private

    def load_and_align
      {}.tap do |aligned|
        raw_data = (File.exist?(@path) && YAML.unsafe_load_file(@path)) || {}
        raw_data.group_by { |k, _| k.split.last }.each do |sha, entries|
          target_lines = @source.lines_with(sha)
          next if target_lines.empty?

          # Old data
          candidates   = entries.map { |key, values| { line: key[/\d+/].to_i, values: values } }
          exact, moved = candidates.partition { |c| target_lines.include?(c[:line]) }
          moved.sort_by! { |c| c[:line] }

          # New aligned data
          target_lines.each do |line|
            match = exact.find { |c| c[:line] == line } || moved.shift
            aligned[line] = match[:values] if match
          end
        end
      end
    end
  end
end
