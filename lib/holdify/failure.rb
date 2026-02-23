# frozen_string_literal: true

require 'yaml'
require 'tempfile'
require 'open3'

module Holdify
  # Diff print failure report
  class Failure
    GUTTER_WIDTH = 3

    def initialize(expected, actual, message, location:, metadata:)
      @expected = expected
      @actual   = actual
      @message  = message
      @location = location
      @metadata = metadata
      @config   = Holdify.config
    end

    def message
      output = add_headers
      @config[:git] ? output.push(*add_diff) : output.push(@message)
      output.join("\n")
    end

    def add_headers
      ["#{ansi[:red]}--- @yaml#{ansi[:reset]} >>> #{@metadata[:path]}:#{@metadata[:line]}",
       "#{ansi[:green]}+++ @test#{ansi[:reset]} >>> #{@location.path}:#{@location.lineno}",
       "#{ansi[:inverse]}<-- #{@metadata[:key]} #{ansi[:reset]}"]
    end

    def ansi
      @config[:color] ? { inverse: "\e[7m", reset: "\e[0m", red: "\e[31m", green: "\e[32m" } : {}
    end

    def git_command
      if @config[:color]
        regex = '[^[:space:]]+|[[:space:]]+'
        %W[git diff --no-index --color-words=#{regex} --unified=1000 #{@exp_file.path} #{@act_file.path}]
      else
        %W[git diff --no-index --no-color --unified=1000 #{@exp_file.path} #{@act_file.path}]
      end
    end

    def add_diff
      @exp_file = create_tempfile(@expected)
      @act_file = create_tempfile(@actual)
      @config[:color] ? color_process_lines : process_lines
    rescue Errno::ENOENT
      []
    ensure
      @exp_file&.close!
      @act_file&.close!
    end

    def diff_lines
      stdout, = Open3.capture3(*git_command)
      return [] if stdout.to_s.empty?

      # Match everything from the start up to the LAST @@...--- sequence
      # .* is greedy, so it skips all earlier hunks
      regex = /\A.*@@.*?\r?\n[[:blank:]]*---(\e\[[0-9;]*m)?\r?\n/m
      body = stdout.sub(regex, '')

      body.split(/\r?\n/)
    end

    def color_process_lines
      line_num = @metadata[:line]
      diff_lines.map do |line|
        clean = line.gsub(/\e\[(1|22|0)m/, '').lstrip
        added = clean.start_with?(ansi[:green]) && !line.include?(ansi[:red])

        if added
          gutter = ' ' * GUTTER_WIDTH
        else
          gutter = line_num.to_s.rjust(GUTTER_WIDTH)
          line_num += 1
        end

        "#{ansi[:inverse]}#{gutter}#{ansi[:reset]} #{line}"
      end
    end

    def process_lines
      line_num = @metadata[:line]
      diff_lines.map do |line|
        type = line[0]
        line = line[1..]

        if type == '+'
          gutter = ' ' * GUTTER_WIDTH
        else
          gutter = line_num.to_s.rjust(GUTTER_WIDTH)
          line_num += 1
        end

        "#{gutter} #{type} #{line}"
      end
    end

    def create_tempfile(obj)
      Tempfile.new(%w[holdify .yaml]).tap do |file|
        file.write(YAML.dump(obj))
        file.flush
      end
    end
  end
end
