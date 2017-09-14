# frozen_string_literal: true

# require 'rspec/its'
require 'net-ldap'
require 'hydra-ldap'
require 'namae'
require 'logger'
require 'mail'

def logger
  Logger.new(STDOUT)
end

# defines the classes availabel for the LdapDisambiguate gem
#
# LdapUser is the interface to the PSU LDAP
# Name uses the name to disambiguate via name
#
module LdapDisambiguate
  autoload :Base, 'ldap_disambiguate/base'
  autoload :Name, 'ldap_disambiguate/name'
  autoload :Email, 'ldap_disambiguate/email'
  autoload :LdapUser, 'ldap_disambiguate/ldap_user'
  autoload :MultipleUserError, 'ldap_disambiguate/multiple_user_error'
end
