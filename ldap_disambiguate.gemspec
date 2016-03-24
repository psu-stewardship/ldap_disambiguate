# frozen_string_literal: true
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ldap_disambiguate/version'

Gem::Specification.new do |s|
  s.name        = 'ldap_disambiguate'
  s.version     = LdapDisambiguate::VERSION
  s.date        = '2016-03-14'
  s.summary     = 'Use ldap to diambiguate a text name'
  s.description = 'Queries the PSU ldap to see if it can find a user that matches the text to get the prefered name and email'
  s.authors     = ['Carolyn Cole']
  s.email       = 'cam156@psu.edu'
  s.files       = ['lib/ldap_disambiguate.rb']
  s.homepage    =
    'https://github.com/psu-stewardship/ldap_disambiguate'
  s.license       = 'APACHE2'

  s.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  s.bindir        = 'exe'
  s.executables   = s.files.grep(%r{^exe/}) { |f| File.basename(f) }
  s.require_paths = ['lib']

  s.add_dependency 'hydra-ldap'
  s.add_dependency 'net-ldap', '0.13.0'
  s.add_dependency 'namae', '0.9.3'

  s.add_development_dependency 'bundler', '~> 1.11'
  s.add_development_dependency 'rake', '~> 10.0'
  s.add_development_dependency 'rspec', '~> 3.0'
  s.add_development_dependency 'rspec-its'
end
