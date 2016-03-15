$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'ldap_disambiguate'

def in_travis
  ENV['TRAVIS']
end
