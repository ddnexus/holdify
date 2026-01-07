# frozen_string_literal: true

require 'yaml'
require 'tempfile'
require 'open3'

module Holdify
  # Generates a pretty diff using git
  module Pretty
    RESET    = "\e[0m"
    RED_FG   = "\e[31m"
    GREEN_FG = "\e[32m"

    G_BASE = "\e[100m #{RESET} ".freeze
    G_EXP  = "\e[41m\e[97m\e[1m-#{RESET} ".freeze
    G_ACT  = "\e[42m\e[97m\e[1m+#{RESET} ".freeze

    class << self
      def call(expected, actual)
        exp_file = create_tempfile(expected)
        act_file = create_tempfile(actual)

        cmd = %W[git diff --no-index --word-diff=porcelain --unified=1000 #{exp_file.path} #{act_file.path}]
        stdout, _stderr, _status = Open3.capture3(*cmd)

        return nil if stdout.empty?

        format(stdout)
      rescue Errno::ENOENT
        nil
      ensure
        exp_file&.close!
        act_file&.close!
      end

      private

      def format(diff)
        lines = diff.lines.map(&:chomp)
        start = lines.index { |l| l.start_with?('@@') }
        return nil unless start

        output  = ["#{G_EXP}#{RED_FG}Held (Expected)#{RESET}", "#{G_ACT}#{GREEN_FG}Current (Actual)#{RESET}"]
        exp_buf = +''
        act_buf = +''

        lines[(start + 1)..].each do |line|
          char = line[0]
          text = line[1..]

          # :nocov:
          case char
          # :nocov:
          when ' '
            exp_buf << text
            act_buf << text
          when '-'
            exp_buf << "#{RED_FG}#{text}#{RESET}"
          when '+'
            act_buf << "#{GREEN_FG}#{text}#{RESET}"
          when '~'
            flush_buffers(output, exp_buf, act_buf)
            exp_buf.clear
            act_buf.clear
          end
        end

        flush_buffers(output, exp_buf, act_buf) unless exp_buf.empty? && act_buf.empty?

        output.join("\n")
      end

      def flush_buffers(output, exp, act)
        if exp == act
          output << "#{G_BASE}#{exp}"
        else
          output << "#{G_EXP}#{exp}"
          output << "#{G_ACT}#{act}"
        end
      end

      def create_tempfile(obj)
        Tempfile.new(%w[holdify .yaml]).tap do |file|
          file.write(YAML.dump(obj, line_width: 78)) # Ensure 80 columns (including pretty gutter)
          file.flush
        end
      end
    end
  end
end
