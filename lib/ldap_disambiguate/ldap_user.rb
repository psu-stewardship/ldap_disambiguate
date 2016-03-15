module LdapDisambiguate
  class LdapUser
    def self.directory_attributes(login, attrs = [])
      filter = Net::LDAP::Filter.eq('uid', login)
      get_ldap_response(:get_user, filter, attrs)
    end

    def self.query_ldap_by_name_or_id(id_or_name_part)
      person_filter = '(| (eduPersonPrimaryAffiliation=STUDENT) (eduPersonPrimaryAffiliation=FACULTY) (eduPersonPrimaryAffiliation=STAFF) (eduPersonPrimaryAffiliation=EMPLOYEE))))'
      filter = Net::LDAP::Filter.construct("(& (| (uid=#{id_or_name_part}* ) (givenname=#{id_or_name_part}*) (sn=#{id_or_name_part}*)) #{person_filter})")
      users  = get_ldap_response(:get_user, filter, %w(uid displayname))

      # handle the issue that searching with a few letters returns more than 1000 items wich causes an error in the system
      if users.nil? && (Hydra::LDAP.connection.get_operation_result[:message] == 'Size Limit Exceeded')
        filter2 = Net::LDAP::Filter.construct("(& (uid=#{id_or_name_part}* ) #{person_filter})")
        users = get_ldap_response(:get_user, filter2, %w(uid displayname))
      end
      users.map { |u| { id: u[:uid].first, text: "#{u[:displayname].first} (#{u[:uid].first})" } }
    end

    def self.query_ldap_by_name(given_name, surname)
      first_names = []
      first_names = given_name.split(/[\s.]+/) unless given_name.blank?
      users = []
      users = get_users("(givenname=#{first_names[0]}*) (givenname=*#{first_names[1]}*) (sn=#{surname})") if first_names.count >= 2
      users = get_users("(givenname=#{first_names[0]}) (sn=#{surname})") if users.count == 0 && first_names.count > 0
      users = get_users("(givenname=#{first_names[0]}*) (sn=#{surname})") if users.count == 0 && first_names.count > 0
      users = get_users("(givenname=*#{first_names[0]}*) (sn=#{surname})") if users.count == 0 && first_names.count > 0
      # users = get_users("(displayname=*#{first_names[0]}*) (displayname=*#{surname}*)") if users.count == 0
      users.map { |u| { id: u[:uid].first, given_name: u[:givenname].first, surname: u[:sn].first, email: u[:mail].first, affiliation: u[:eduPersonPrimaryAffiliation] } }
    end

    def self.get_users(name_filter)
      person_filter = '(| (eduPersonPrimaryAffiliation=STUDENT) (eduPersonPrimaryAffiliation=FACULTY) (eduPersonPrimaryAffiliation=STAFF) (eduPersonPrimaryAffiliation=EMPLOYEE) (eduPersonPrimaryAffiliation=RETIREE) (eduPersonPrimaryAffiliation=EMERITUS) (eduPersonPrimaryAffiliation=MEMBER)))'
      filter = Net::LDAP::Filter.construct("(& (& #{name_filter}) #{person_filter})")
      get_ldap_response(:get_user, filter, %w(uid givenname sn mail eduPersonPrimaryAffiliation))
    end

    private

    def self.get_ldap_response(_method, filter, attributes)
      tries.times.each do
        result = Hydra::LDAP.get_user(filter, attributes)
        return result unless unwilling?
        sleep(sleep_time)
      end
      nil
    end

    def self.tries
      7
    end

    # Numeric code returned by LDAP if it is feeling "unwilling"
    def self.unwilling?
      Hydra::LDAP.connection.get_operation_result.code == 53
    end

    def self.sleep_time
      1.0
    end
  end
end
