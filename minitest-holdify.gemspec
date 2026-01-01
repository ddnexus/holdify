# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name        = 'minitest-holdify'
  s.version     = '1.0.1'
  s.authors     = ['Domizio Demichelis']
  s.email       = ['dd.nexus@gmail.com']
  s.summary     = 'Hardcoded values suck! Holdify them.'
  s.description = 'Stop maintaining large expected values in your test/fixture files! ' \
                  'Hold them automatically. Update them effortlessly.'
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
