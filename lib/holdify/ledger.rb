# frozen_string_literal: true

require 'yaml'
require 'fileutils'

module Holdify
  # Manages the persistence and alignment of stored values
  class Ledger
    def initialize(path, source)
      @path   = "#{path}#{CONFIG[:ext]}"
      @source = source
      FileUtils.rm_f(@path) if Holdify.reconcile
      @data = File.exist?(@path) ? load_and_align : {}
    end

    def get(line) = @data[line]

    def set(line, values) = (@data[line] = values)

    def persist
      return FileUtils.rm_f(@path) if @data.empty?

      output = {}
      @data.keys.sort.each do |line|
        xxh = @source.xxh(line)
        next unless xxh

        output["L#{line} #{xxh}"] = @data[line]
      end

      content = YAML.dump(output, line_width: 78) # Ensure 80 columns (including pretty gutter)
      File.write(@path, content)
    end

    private

    def load_and_align
      {}.tap do |aligned|
        data = YAML.unsafe_load_file(@path) || {}
        data.group_by { |k, _| k.split.last }.each do |xxh, entries|
          lines = @source.lines(xxh)
          next if lines.empty?

          # Position of the held lines compared to the source lines
          stayed, moved = entries.map { |key, values| { line: key[/\d+/].to_i, values: values } }
                                 .partition { |c| lines.include?(c[:line]) }
          moved.sort_by! { |c| c[:line] }

          # Align lines
          lines.each do |line|
            match         = stayed.find { |c| c[:line] == line } || moved.shift
            aligned[line] = match[:values] if match
          end
        end
      end
    end
  end
end
