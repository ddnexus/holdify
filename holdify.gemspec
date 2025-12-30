# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name        = 'holdify'
  s.version     = '1.0.0'
  s.authors     = ['Domizio Demichelis']
  s.email       = ['dd.nexus@gmail.com']
  s.summary     = 'Hardcoded values suck! Hold them inline!'
  s.description = 'Holdify eliminates the burden of maintaining large expected values into your test files. ' \
                  'It behaves as if the expected value were hardcoded inline, but keeps it stored externally. ' \
                  'This ensures your values hold true without polluting your test files, ' \
                  'and allows for effortless updates when your code changes.'
  s.homepage    = 'https://github.com/ddnexus/holdify'
  s.license     = 'MIT'
  s.files       = Dir['lib/**/*.rb'] + ['LICENSE.txt']
  s.metadata    = { 'rubygems_mfa_required' => 'true',
                    'homepage_uri'          => 'https://github.com/ddnexus/holdify',
                    'bug_tracker_uri'       => 'https://github.com/ddnexus/holdify/issues',
                    'changelog_uri'         => 'https://github.com/ddnexus/holdify/blob/master/CHANGELOG.md' }
  s.required_ruby_version = '>= 3.2'
  s.add_dependency 'minitest', '>= 5.0.0'
end
