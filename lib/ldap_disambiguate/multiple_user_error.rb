# frozen_string_literal: true
module LdapDisambiguate
  # This error is thrown if we get more than one user back from ldap for an input
  #
  class MultipleUserError < RuntimeError
  end
end
