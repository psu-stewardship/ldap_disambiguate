require 'rspec/its'
require 'net-ldap'
require 'hydra-ldap'
require 'namae'
require 'logger'

def logger
  Logger.new(STDOUT)
end

module LdapDisambiguate
  autoload :Name, 'ldap_disambiguate/name'
  autoload :LdapUser, 'ldap_disambiguate/ldap_user'
end
