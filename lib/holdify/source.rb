# frozen_string_literal: true

require 'digest/xxhash'

module Holdify
  # Represents the current state of the source file
  class Source
    def initialize(path) = (@line_xxh, @xxh_lines = parse(path))

    def xxh(lineno) = @line_xxh[lineno]

    def lines(xxh) = @xxh_lines[xxh]

    private

    def parse(path)
      line_xxh  = {}
      xxh_lines = Hash.new { |h, k| h[k] = [] }

      File.foreach(path).with_index(1) do |text, lineno|
        content = text.strip
        next if content.empty?

        xxh = Digest::XXH3_64bits.hexdigest(content)
        line_xxh[lineno] = xxh
        xxh_lines[xxh] << lineno
      end

      [line_xxh, xxh_lines]
    end
  end
end
