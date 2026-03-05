# frozen_string_literal: true

require 'yaml'
require 'tempfile'
require 'open3'

module Holdify
  # Feedback report on failure
  class Feedback
    def initialize(hold, hold_ref, *args)
      yaml_path = hold.store.path
      @yaml_lno = find_yaml_lno(hold, yaml_path)
      @yaml_ref = Holdify.relativize("#{yaml_path}:#{@yaml_lno}")

      @hold_ref = Holdify.relativize(hold_ref)
      test_ref  = Holdify.relativize(hold.test_loc.to_s.sub(/:in .*$/, ''))
      @test_ref = test_ref unless @hold_ref == test_ref

      @expected, @actual, @message = *args

      # Extend features
      extend Color if Holdify.color
      return unless Holdify.git_diff

      @diff_yaml_headers = 2    # ----expected and +---actual (no sgr code) on 2 lines
      extend GitDiff            # rubocop:disable Layout/EmptyLinesAfterModuleInclusion
      return unless Holdify.color

      @diff_yaml_headers = 1    # ---expected---actual (with sgr codes) on single line
      extend Color::GitDiff
    end

    def render = [@message, *file_refs, *diff, ''].join("\n")

    def file_refs
      ["--- @stored --> #{@yaml_ref}", "+++ @tested --> #{@hold_ref}"].tap do |refs|
        refs << "            --> #{@test_ref}" if @test_ref
      end
    end

    def diff = ["-#{@expected.inspect}", "+#{@actual.inspect}"]

    private

    def find_yaml_lno(hold, yaml_path)
      test_lno = hold.test_loc.lineno
      index    = hold.session[test_lno].size - 1   # current index
      xxh      = hold.store.xxh(test_lno)

      found = false
      count = -1
      File.foreach(yaml_path).with_index(1) do |line, ln|
        if found
          next unless line.start_with?('-')

          count += 1
          next unless count == index

          return ln
        else
          found = line.match(/^L#{test_lno}-#{xxh}:$/)
        end
      end
    end

    # Methods enabling the git-diff feedback (no-color)
    module GitDiff
      def git_command = "git diff --no-index --no-color --unified=1000 #{@exp_path} #{@act_path}"

      def diff
        @exp_path = create_tempfile(@expected, 'expected').path
        @act_path = create_tempfile(@actual, 'actual').path

        stdout, = Open3.capture3(git_command)
        regex   = /\A[^@]*\r?\n/m   # cleanup git headers
        lines   = stdout.sub(regex, '').split(/\r?\n/)

        process_lines(lines)
      ensure
        # :nocov:
        File.unlink(@exp_path) if @exp_path
        File.unlink(@act_path) if @act_path
        # :nocov:
      end

      def create_tempfile(obj, type)
        Tempfile.create.tap do |file|
          file.write(Store.hold_dump(obj).sub(/(?=\n)/, type))
          file.close
        end
      end

      def process_lines(lines)
        width  = 0
        lineno = [@yaml_lno - 1]
        lines.map.with_index do |line, i|
          if i.zero? # @@ ... @@
            width, line = render_hunk(line)
            next line
          elsif i <= @diff_yaml_headers # ---
            next
          end

          render_line(line, lineno, width)
        end.compact
      end

      # Reduce the hunk lines by 1 and calculate the gutter width
      def render_hunk(line)
        width = 0
        hunk  = line.gsub(/([-+]\d+),(\d+)\s+([-+]\d+),(\d+)/) do
                  v1,   = $2.to_i - 1          # rubocop:disable Style/PerlBackrefs
                  v2    = $4.to_i - 1          # rubocop:disable Style/PerlBackrefs
                  width = (@yaml_lno + [v1, v2].max).to_s.length
                  "#{$1},#{v1} #{$3},#{v2}"    # rubocop:disable Style/PerlBackrefs
                end

        [width, hunk]
      end

      def render_line(line, lineno, width)
        type   = line[0]
        line   = line[1..]
        gutter = if type == '+'
                   ' ' * width
                 else
                   lineno[0] += 1
                   lineno[0].to_s.rjust(width)
                 end

        "#{type}#{gutter} #{line}"
      end
    end

    # Methods enabling ANSI feedback
    module Color
      SGR = { clear:   "\e[0m",
              red:     "\e[31m",
              green:   "\e[32m",
              yellow:  "\e[33m",
              magenta: "\e[35m" }.freeze

      def dye(color, string) = "#{SGR[color]}#{string}#{SGR[:clear]}"

      def file_refs
        refs = super
        [dye(:red, refs.shift), *refs.map { dye(:green, _1) }]
      end

      def diff = [dye(:red, "-#{@expected.inspect}"), dye(:green, "+#{@actual.inspect}")]

      # Methods enabling the git-diff ANSI feedback
      module GitDiff
        def git_command
          # Words/ruby entities | indent | other single-chars
          re = '[[:alnum:]_:]+|[[:space:]]+|.'
          "git diff --no-index --color-words='#{re}' --unified=1000 #{@exp_path} #{@act_path}"
        end

        def render_line(line, lineno, width)
          clean   = line.gsub(/\e\[(1|22|0)m/, '').lstrip
          added   = clean.start_with?(SGR[:green]) && !line.include?(SGR[:red])
          removed = clean.start_with?(SGR[:red]) && !line.include?(SGR[:green])
          changed = line.include?(SGR[:red]) || line.include?(SGR[:green])

          type, color = (added && ['+', :green]) || (removed && ['-', :red]) || (changed && ['~', :yellow])

          sgr    = SGR[color].to_s if color
          gutter = if added
                     "#{sgr}#{type}#{' ' * width}#{SGR[:clear]}"
                   else
                     lineno[0] += 1
                     "#{sgr}#{type || ' '}#{lineno[0].to_s.rjust(width)}#{SGR[:clear] if sgr}"
                   end

          "#{gutter} #{line}"
        end
      end
    end
  end
end
