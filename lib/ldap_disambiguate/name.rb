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
        results ||= lookup_text_only_names(name) # straight text we need to query ldap
        results
      end

      def clear_cache
        @email_for_name_cache = {}
      end

      private

      def lookup_text_only_names(multi_name)
        results = separate_names(multi_name).map do |name|
          lookup_name(clean_name(name))
        end
        results.reject(&:blank?)
      end

      def lookup_name(name)
        query_result = email_for_name(name)
        query_result ||= title_after_name(name) # try again without the titles
        query_result
      rescue MultipleUserError
        return nil
      end

      def email_for_name(text_name)
        return '' if text_name.blank? || word_count(text_name) < 2
        return email_for_name_cache[text_name] if email_for_name_cache.key?(text_name)

        email_for_name_cache[text_name] = translate_name_to_email(text_name)
      end

      # titles after the name that namae had trouble parsing
      def title_after_name(text_name)
        email_for_name(remove_titles(text_name))
      end

      def translate_name_to_email(text_name)
        parsed = Namae::Name.parse(text_name)

        result = try_name(parsed.given, parsed.family)
        result ||= title_before_name(parsed)
        result ||= two_words_in_last_name(text_name)
        result
      end

      def try_name(given, family)
        return nil if family.blank?

        possible_users = LdapUser.query_ldap_by_name(given, family, ldap_attrs)
        raise(MultipleUserError, "too name results for #{given} #{family}") if possible_users.count > 1
        possible_users.first
      end

      def title_before_name(parsed)
        return unless parsed.given && multi_word?(parsed.given)

        parts = name_parts(parsed.given, 1)
        return if only_initial?(parts[:family])

        try_name(parts[:family], parsed.family)
      end

      def two_words_in_last_name(text_name)
        return unless word_count(text_name) > 2

        parts = name_parts(text_name, 2)
        try_name(parts[:given], parts[:family])
      end

      def name_parts(text_name, last_name_count)
        return if word_count(text_name) < (last_name_count + 1)

        parts = split_name_parts(text_name)
        first_name_count = parts.count - last_name_count
        { given: parts.first(first_name_count).join(' '), family: parts.last(last_name_count).join(' ') }
      end

      def clean_name(name)
        name.gsub(/\([^)]*\)/, '')
            .gsub(/[^\w\s,']/, ' ')
            .strip.squeeze(' ')
      end

      def multi_word?(name)
        word_count(name) > 1
      end

      def word_count(name)
        name.squeeze(' ').count(' ') + 1
      end

      def split_name_parts(name)
        name.split(' ')
      end

      def only_initial?(name)
        name.size <= 1
      end

      def separate_names(multi_name)
        multi_name.split(/ and |;/)
      end

      def remove_titles(name)
        name.split(',')[0]
      end

      def email_for_name_cache
        @email_for_name_cache ||= {}
      end
    end
  end
end
