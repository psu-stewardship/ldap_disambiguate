# frozen_string_literal: true
$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'ldap_disambiguate'
require 'support/ldap'
require 'byebug'

def in_travis
  ENV['TRAVIS']
end
