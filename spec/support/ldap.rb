def expect_ldap(method, response, *args)
  return unless in_travis
  expect(LdapDisambiguate::LdapUser).to receive(method).with(*args).and_return(response)
end

def format_ldap_response(id, first_name, last_name, affiliation = 'STAFF')
  [{ uid: [id],
     givenname: [first_name],
     sn: [last_name],
     mail: ["#{id}@psu.edu"],
     eduPersonPrimaryAffiliation: [affiliation] }]
end

def format_name_response(id, first_name, last_name, affiliation = 'STAFF')
  [{ id: id,
     given_name: first_name,
     surname: last_name,
     email: "#{id}@psu.edu",
     affiliation: [affiliation],
     displayname: "#{first_name} #{last_name}" }]
end
