# frozen_string_literal: true
require 'spec_helper'

describe LdapDisambiguate::Email do
  let(:ldap_fields) { [:uid, :givenname, :sn, :mail, :eduPersonPrimaryAffiliation, :displayname] }
  subject { described_class.disambiguate(name) }
  before do
    allow(LdapDisambiguate::LdapUser).to receive(:directory_attributes).with(name, ldap_fields).and_return([]) if in_travis
    expect(LdapDisambiguate::LdapUser).not_to receive(:get_users) if in_travis
  end

  context 'when the email is not their id' do
    let(:name) { 'Barbara I. Dewey a bdewey@psu.edu' }
    it 'does not find the user' do
      expect_ldap(:directory_attributes, [], 'bdewey', ldap_fields)
      is_expected.to eq([{ id: '', given_name: '', surname: '', email: 'bdewey@psu.edu', affiliation: [], displayname: '' }])
    end
  end

  context 'when the email is their id' do
    let(:name) { 'sjs230@psu.edu' }
    let(:response) { format_ldap_response('sjs230', 'SARAH J', 'STAGER') }
    it 'finds the user' do
      expect_ldap(:directory_attributes, response, 'sjs230', ldap_fields)
      expect(subject.count).to eq(1)
    end
  end

  context 'when the email is a list of ids' do
    let(:name) { 'sjs230@psu.edu, cam156@psu.edu' }
    let(:response1) { format_ldap_response('sjs230', 'SARAH J', 'STAGER') }
    let(:response2) { format_ldap_response('cam156', 'CAROLYN A', 'cole') }
    it 'finds the user' do
      expect_ldap(:directory_attributes, response1, 'sjs230', ldap_fields)
      expect_ldap(:directory_attributes, response2, 'cam156', ldap_fields)
      expect(subject.count).to eq(2)
    end
  end
end
