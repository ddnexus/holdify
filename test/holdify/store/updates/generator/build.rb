#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'
ENV['SKIP_COVERAGE'] = 'true'

GENERATOR_DIR = __dir__
CASES_DIR     = File.join(GENERATOR_DIR, 'cases')
TARGET_DIR    = File.expand_path('..', GENERATOR_DIR)
GEN_HELPER    = File.join(GENERATOR_DIR, 'gen_helper.rb')

# Paths for ruby execution
LIB_PATH  = File.expand_path('../../../../../lib', GENERATOR_DIR)
TEST_PATH = File.expand_path('../../../..', GENERATOR_DIR) # Points to test/

# Extension used by Holdify (assumed .yaml based on context, but could be dynamic)
EXT = '.yaml'

puts "== Holdify Test Generator =="
puts "Source: #{CASES_DIR}"
puts "Target: #{TARGET_DIR}"

Dir.glob(File.join(CASES_DIR, '*')).each do |case_dir|
  next unless File.directory?(case_dir)

  case_name = File.basename(case_dir)
  puts "\nProcessing case: #{case_name}"

  # 1. Inject the generator helper
  # We copy it to 'helper.rb' so require_relative 'helper' in the test files works
  FileUtils.cp(GEN_HELPER, File.join(case_dir, 'helper.rb'))

  begin
    # 2. Run base.rb to generate the INITIAL store state
    # This creates base.rb.yaml
    puts "  Generating base state..."
    system("ruby", "-I#{LIB_PATH}", "-I#{TEST_PATH}", File.join(case_dir, 'base.rb'))

    abort "  [ERROR] Failed to generate base store for #{case_name}" unless File.exist?(File.join(case_dir, "base.rb#{EXT}"))

    # 3. Run changed.rb to generate the EXPECTED store state
    # This creates changed.rb.yaml
    puts "  Generating expected state..."
    system("ruby", "-I#{LIB_PATH}", "-I#{TEST_PATH}", File.join(case_dir, 'changed.rb'))

    unless File.exist?(File.join(case_dir, "changed.rb#{EXT}"))
      abort "  [ERROR] Failed to generate expected store for #{case_name}"
    end

    # 4. Move and Rename Artifacts to Target Directory
    # base.rb.yaml    -> [case]_test.rb.yaml (The initial store)
    FileUtils.mv(File.join(case_dir, "base.rb#{EXT}"), File.join(TARGET_DIR, "#{case_name}_test.rb#{EXT}"))

    # changed.rb.yaml -> [case]_test_after_change.rb.yaml (The expected store)
    FileUtils.mv(File.join(case_dir, "changed.rb#{EXT}"), File.join(TARGET_DIR, "#{case_name}_test_after_change.rb#{EXT}"))

    # changed.rb      -> [case]_test.rb (The actual test file)
    FileUtils.cp(File.join(case_dir, 'changed.rb'), File.join(TARGET_DIR, "#{case_name}_test.rb"))
  ensure
    FileUtils.rm_f(File.join(case_dir, 'helper.rb'))
  end
end
