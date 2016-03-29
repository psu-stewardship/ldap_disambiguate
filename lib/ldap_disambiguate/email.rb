# frozen_string_literal: true
module LdapDisambiguate
  # This class allows you to use LDAP to extract user information
  #  from an email or list of emails
  #
  class Email < Base
    class << self
      def disambiguate(email)
        return unless email.include?('@')
        email_in_name(email)
      end

      private

      def email_in_name(email_list)
        parts = email_list.split(' ')
        emails = parts.reject { |part| !part.include?('@') }
        results = []
        Array(emails).each do |email_str|
          email = Mail::Address.new(email_str)
          results << (ldap_attributes_for_id(email.local) || ldap_attributes_for_email(email.address) || [LdapUser.results_hash(mail: [email.address])]).first
        end
        results
      end

      def ldap_attributes_for_email(email)
        users = LdapUser.query_ldap_by_mail(email, ldap_attrs)
        users.count < 1 ? nil : users
      end
    end
  end
end
