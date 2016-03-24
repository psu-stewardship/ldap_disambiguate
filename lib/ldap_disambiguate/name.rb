# frozen_string_literal: true
module LdapDisambiguate
  # This class allows you to use LDAP to disambiguate a text name
  #
  class Name < Base
    class << self
      def disambiguate(name)
        return if name.blank?
        results = ldap_attributes_for_id(name) # text includes login id
        results ||= Email.disambiguate(name) # text includes email(s)
        results ||= text_only_names(name) # straight text we need to query ldap
        results
      end

      private

      def text_only_names(multi_name)
        results = []
        multi_name.split(/and|;/).each do |n|
          n.gsub!(/\([^)]*\)/, '')
          n.strip!
          query_result = email_for_name(n)
          query_result ||= title_after_name(n) # try again without the titles
          results << query_result unless query_result.blank?
        end
        results
      end

      # titles after the name that namae had trouble parsing
      def title_after_name(text_name)
        result = nil
        if text_name.count(',') > 0
          new_name = text_name.split(',')[0]
          result = email_for_name(new_name) if new_name.count(' ') > 0
        end
        result
      end

      def email_for_name(text_name)
        return '' if text_name.blank?
        return email_for_name_cache[text_name] unless email_for_name_cache[text_name].blank?

        email_for_name_cache[text_name] = find_email_for_name(text_name)
        email_for_name_cache[text_name]
      end

      def email_for_name_cache
        @email_for_name_cache ||= {}
      end

      def find_email_for_name(text_name)
        text_name.gsub!(/[^\w\s,']/, ' ')
        parsed = Namae::Name.parse(text_name)
        result = try_name(parsed.given, parsed.family)
        result ||= title_before_name(parsed)
        result ||= two_words_in_last_name(text_name)

        logger.error("got zero for #{text_name}") if result.nil?
        result
      end

      def try_name(given, family)
        return nil if family.blank?
        possible_users = LdapUser.query_ldap_by_name(given, family, ldap_attrs)
        return nil if possible_users.count == 0
        if possible_users.count > 1
          logger.error("Returning #{possible_users.first} but got more than name for given name #{given} and family name #{name}")
          return nil
        end
        possible_users.first
      end

      def name_parts(text_name, last_name_count)
        parts = text_name.split(' ')
        first_name_count = parts.count - last_name_count
        return nil if first_name_count < 1
        { given: parts.first(first_name_count).join(' '), family: parts.last(last_name_count).join(' ') }
      end

      # take first name and break it into first and last with last name conatining one word
      def title_before_name(parsed)
        return unless parsed
        result = nil
        if parsed.given && parsed.given.count(' ') >= 1
          parts = name_parts(parsed.given, 1)
          result = try_name(parts[:family], parsed.family)
        end
        result
      end

      def two_words_in_last_name(text_name)
        result = nil
        if text_name.count(' ') > 2
          parts = name_parts(text_name, 2)
          result = try_name(parts[:given], parts[:family])
        end
        result
      end
  end
  end
end
