# frozen_string_literal: true

module LdapDisambiguate
  # This class allows you to use LDAP to disambiguate a text name
  #
  class Base
    class << self
      private

      def ldap_attributes_for_id(id)
        users = LdapUser.directory_attributes(id, ldap_attrs)
        users.count < 1 ? nil : users
      end

      def ldap_attrs
        %i[uid givenname sn mail eduPersonPrimaryAffiliation displayname]
      end
    end
  end
end
