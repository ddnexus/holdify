# frozen_string_literal: true

require 'digest/sha1'

module Holdify
  # Represents the current state of the source file
  class Source
    def initialize(path) = (@line_sha, @sha_lines = parse(path))

    def sha_at(line) = @line_sha[line]

    def lines_with(sha) = @sha_lines[sha]

    private

    def parse(path)
      line_sha  = {}
      sha_lines = Hash.new { |h, k| h[k] = [] }

      File.foreach(path).with_index(1) do |text, line|
        content = text.strip
        next if content.empty?

        sha = Digest::SHA1.hexdigest(content)
        line_sha[line] = sha
        sha_lines[sha] << line
      end

      [line_sha, sha_lines]
    end
  end
end
