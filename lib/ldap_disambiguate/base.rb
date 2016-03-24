# frozen_string_literal: true
module LdapDisambiguate
  # This class allows you to use LDAP to disambiguate a text name
  #
  class Base
    class << self
      private

      def ldap_attributes_for_id(id)
        attrs = LdapUser.directory_attributes(id, ldap_attrs)
        return nil if attrs.count < 1
        [results_hash(attrs.first)]
      end

      def results_hash(opts)
        {
          id:          fetch(opts, :uid).first,
          given_name:  fetch(opts, :givenname).first,
          surname:     fetch(opts, :sn).first,
          email:       fetch(opts, :mail).first,
          affiliation: fetch(opts, :eduPersonPrimaryAffiliation, []),
          displayname: fetch(opts, :displayname).first
        }
      end

      def fetch(opts, key, default = [''])
        opts[key].blank? ? default : opts[key]
      end

      def ldap_attrs
        [:uid, :givenname, :sn, :mail, :eduPersonPrimaryAffiliation, :displayname]
      end
    end
  end
end
