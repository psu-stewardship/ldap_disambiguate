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
        Array(emails).each do |email|
          id = email.split('@')[0]
          results << (ldap_attributes_for_id(id) || [results_hash(mail: [email])]).first
        end
        results
      end
    end
  end
end
