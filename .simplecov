# frozen_string_literal: true

SimpleCov.start do
  track_files 'lib/**/*.rb'
  add_filter %w[/test/ /minitest-holdify.rb]
  enable_coverage :branch
  minimum_coverage line: 100, branch: 100
end
