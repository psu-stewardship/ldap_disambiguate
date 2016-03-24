# frozen_string_literal: true
module LdapDisambiguate
  # This class provides an api for quering LDAP with different portions of the user's
  # information (name parts or id)
  class LdapUser
    class << self
      def directory_attributes(login, attrs = [])
        filter = Net::LDAP::Filter.eq('uid', login)
        get_ldap_response(:get_user, filter, attrs)
      end

      def query_ldap_by_name_or_id(id_or_name_part)
        filter = Net::LDAP::Filter.construct("(& (| (uid=#{id_or_name_part}* ) (givenname=#{id_or_name_part}*) (sn=#{id_or_name_part}*)) #{person_filter})")
        users  = get_ldap_response(:get_user, filter, %w(uid displayname))

        # handle the issue that searching with a few letters returns more than 1000 items wich causes an error in the system
        users = get_user_by_partial_id(id_or_name_part) if size_limit_exceeded?
        users.map { |u| { id: u[:uid].first, text: "#{u[:displayname].first} (#{u[:uid].first})" } }
      end

      def query_ldap_by_name(given_name, surname, attrs = [])
        return if given_name.blank? # this method only work if we have a first name to play with

        first_names = given_name.split(/[\s.]+/)
        users = []
        name_filters(first_names[0], first_names[1], surname).each do |filter|
          users = get_users(filter, attrs)
          break if users.count > 0 # stop running through the filters if we get results
        end
        format_users(users, attrs)
      end

      def get_users(name_filter, attrs = [])
        attrs = (attrs + default_attributes).uniq
        person_filter = '(| (eduPersonPrimaryAffiliation=STUDENT) (eduPersonPrimaryAffiliation=FACULTY) (eduPersonPrimaryAffiliation=STAFF) (eduPersonPrimaryAffiliation=EMPLOYEE) (eduPersonPrimaryAffiliation=RETIREE) (eduPersonPrimaryAffiliation=EMERITUS) (eduPersonPrimaryAffiliation=MEMBER)))'
        filter = Net::LDAP::Filter.construct("(& (& #{name_filter}) #{person_filter})")
        get_ldap_response(:get_user, filter, attrs)
      end

      private

      def format_users(users, attrs)
        user_attrs = attrs - default_attributes
        users.map { |u| format_user(u, user_attrs) }
      end

      def format_user(user, extra_attrs)
        hash = { id: user[:uid].first, given_name: user[:givenname].first, surname: user[:sn].first, email: user[:mail].first, affiliation: user[:eduPersonPrimaryAffiliation] }
        extra_attrs.each { |attr| hash[attr] = user[attr].first }
        hash
      end

      def get_user_by_partial_id(_id)
        filter = Net::LDAP::Filter.construct("(& (uid=#{id_or_name_part}* ) #{person_filter})")
        get_ldap_response(:get_user, filter, %w(uid displayname))
      end

      def get_ldap_response(_method, filter, attributes)
        tries.times.each do
          result = Hydra::LDAP.get_user(filter, attributes)
          return result unless unwilling?
          sleep(sleep_time)
        end
        nil
      end

      def tries
        7
      end

      # Numeric code returned by LDAP if it is feeling "unwilling"
      def unwilling?
        Hydra::LDAP.connection.get_operation_result.code == 53
      end

      def size_limit_exceeded?
        Hydra::LDAP.connection.get_operation_result[:message] == 'Size Limit Exceeded'
      end

      def sleep_time
        1.0
      end

      def person_filter
        '(| (eduPersonPrimaryAffiliation=STUDENT) (eduPersonPrimaryAffiliation=FACULTY) (eduPersonPrimaryAffiliation=STAFF) (eduPersonPrimaryAffiliation=EMPLOYEE))))'
      end

      def name_filters(first_name, middle_name, surname)
        filters = []
        filters << "(givenname=#{first_name}*) (givenname=* #{middle_name}*) (sn=#{surname})" unless middle_name.blank?
        filters << "(givenname=#{first_name}) (sn=#{surname})"
        filters << "(givenname=#{first_name}*) (sn=#{surname})"
        filters << "(givenname=*#{first_name}*) (sn=#{surname})"
        filters
      end

      def default_attributes
        [:uid, :givenname, :sn, :mail, :eduPersonPrimaryAffiliation]
      end
    end
  end
end
