# frozen_string_literal: true

require 'yaml'
require 'fileutils'
require 'forwardable'

module Holdify
  # Interface to the Source (code) and the Ledger (data)
  class Store
    class NoAliasVisitor < Psych::Visitors::YAMLTree # :nodoc:
      def register(target, obj); end
    end

    extend Forwardable

    def_delegator :@source, :xxh
    attr_reader :path

    def initialize(path)
      @path   = "#{path}#{Holdify.store_ext}"
      @source = Source.new(path)
      FileUtils.rm_f(@path) if Holdify.reconcile
      @data = File.exist?(@path) ? load_and_align : {}
    end

    def get_values(lineno) = @data[lineno]

    def set_values(lineno, values) = (@data[lineno] = values)

    def persist
      return FileUtils.rm_f(@path) if @data.empty?

      output = {}
      @data.keys.sort.each do |lineno|
        xxh = @source.xxh(lineno)
        next unless xxh

        output["L#{lineno} #{xxh}"] = @data[lineno]
      end

      File.write(@path, hold_dump(output))
    end

    private

    def hold_dump(obj)
      visitor = NoAliasVisitor.create
      visitor << obj
      visitor.tree.to_yaml
    end

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
          lines.each do |lineno|
            match           = stayed.find { _1[:line] == lineno } || moved.shift
            aligned[lineno] = match[:values] if match
          end
        end
      end
    end
  end
end
