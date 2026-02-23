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

      content = YAML.dump(output)
      File.write(@path, content)
    end

    # Used in Failure to get the actual storage metadata
    def lookup(lineno, index = 0)
      return unless File.exist?(@path)

      xxh   = @source.xxh(lineno)
      key   = "L#{lineno} #{xxh}"

      found = false
      count = -1

      File.foreach(@path).with_index(1) do |content, ln|
        if found
          next unless content.start_with?('-')

          count += 1
          next unless count == index

          return { path: @path, line: ln, key: key }
        else
          found = content.match(/\b#{xxh}\b/)
        end
      end
    end

    private

    def load_and_align
      {}.tap do |aligned|
        data = YAML.unsafe_load_file(@path) || {}
        data.group_by { |k, _| k.split.last }.each do |xxh, entries|
          lines = @source.lines(xxh)
          next if lines.empty?

          # Position of the held lines compared to the source lines
          stayed, moved = entries.map { |key, values| { line: key[/\d+/].to_i, values: } }
                                 .partition { lines.include?(_1[:line]) }
          moved.sort_by! { _1[:line] }

          # Align lines
          lines.each do |line|
            match         = stayed.find { _1[:line] == line } || moved.shift
            aligned[line] = match[:values] if match
          end
        end
      end
    end
  end
end
