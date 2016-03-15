# ldap_dsiambiguate
Use ldap to disambiguate a user name against the PSU LDAP.

## Useage

Instantiate the servercive with a string `LdapDisambiguate::Name.new("jbd123")`
Call the disambiguate method which returns an array of people in the format `[{:id=>"jbd123", :given_name=>"Jane B", :surname=>"Doe", :email=>"jbd123@psu.edu", :affiliation=>["STAFF"]}]`

What you pass in as the nam can vary from an id to a list of names and or emails.

### Basic usage with a id

You can call dismabiguate with an id, which then call ldap and returns a record containing the 

```
service = LdapDisambiguate::Name.new("cam156") # #<LdapDisambiguate::Name:0x007fab36190710 @name="cam156", @email_for_name_cache={}, @results=[]>
service.disambiguate #[{:id=>"cam156", :given_name=>"CAROLYN A", :surname=>"COLE", :email=>"cam156@psu.edu", :affiliation=>["STAFF"]}]
```

### Basic usage with a name

```
service = LdapDisambiguate::Name.new("Carolyn Cole") # #<LdapDisambiguate::Name:0x007fab36190710 @name="Carolyn Cole", @email_for_name_cache={}, @results=[]>
service.disambiguate #[{:id=>"cam156", :given_name=>"CAROLYN A", :surname=>"COLE", :email=>"cam156@psu.edu", :affiliation=>["STAFF"]}]
```

### Useage with last name and first name part
```
service = LdapDisambiguate::Name.new("Carol Cole") # #<LdapDisambiguate::Name:0x007fab36190710 @name="Carol Cole", @email_for_name_cache={}, @results=[]>
service.disambiguate #[{:id=>"cam156", :given_name=>"CAROLYN A", :surname=>"COLE", :email=>"cam156@psu.edu", :affiliation=>["STAFF"]}]
```

### Useage with last name and first name part
```
service = LdapDisambiguate::Name.new("Carol Cole, cam156") # #<LdapDisambiguate::Name:0x007fab36190710 @name="Carol Cole", @email_for_name_cache={}, @results=[]>
service.disambiguate #[{:id=>"cam156", :given_name=>"CAROLYN A", :surname=>"COLE", :email=>"cam156@psu.edu", :affiliation=>["STAFF"]}]
```

### Useage with a list of names
```
service = LdapDisambiguate::Name.new("Carol Cole; Adam Wead") ##<LdapDisambiguate::Name:0x007fab32cf2418 @name="Carol Cole; Adam Wead", @email_for_name_cache={}, @results=[]>
service.disambiguate #[{:id=>"cam156", :given_name=>"CAROLYN A", :surname=>"COLE", :email=>"cam156@psu.edu", :affiliation=>["STAFF"]}, {:id=>"agw13", :given_name=>"ADAM GARNER", :surname=>"WEAD", :email=>"agw13@psu.edu", :affiliation=>["STAFF"]}]
```

