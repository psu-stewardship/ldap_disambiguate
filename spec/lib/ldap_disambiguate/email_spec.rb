# frozen_string_literal: true

require 'spec_helper'

describe LdapDisambiguate::Email do
  let(:ldap_fields) { %i[uid givenname sn mail eduPersonPrimaryAffiliation displayname] }
  subject { described_class.disambiguate(name) }

  context 'when the email is not their id' do
    let(:name) { 'Zuleima Karpyn & Turgay Ertekin ZKarpyn@psu.edu' }
    let(:response) { format_name_response('ztk101', 'Zuleima T', 'Karpyn', 'FACULTY') }
    it 'finds the user via email' do
      expect_ldap(:directory_attributes, [], 'ZKarpyn', ldap_fields)
      expect_ldap(:query_ldap_by_mail, response, 'ZKarpyn@psu.edu', ldap_fields)
      is_expected.to eq([{ id: "ztk101", given_name: "Zuleima T", surname: "Karpyn", email: "ztk101@psu.edu", affiliation: ["FACULTY"], displayname: "Zuleima T Karpyn" }])
    end
  end

  context 'when the email is not their id and not in ldap' do
    let(:name) { 'Zuleima Karpyn & Turgay Ertekin ZKarpyn2@psu.edu' }
    it 'finds the user via email' do
      expect_ldap(:directory_attributes, [], 'ZKarpyn2', ldap_fields)
      expect_ldap(:query_ldap_by_mail, [], 'ZKarpyn2@psu.edu', ldap_fields)
      is_expected.to eq([{ id: '', given_name: '', surname: '', email: "ZKarpyn2@psu.edu", affiliation: [], displayname: "" }])
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

  context 'when the email contains a name too' do
    let(:name) { '"Richard Stedman" <RStedman@psu.edu>' }
    it 'finds the user' do
      expect_ldap(:directory_attributes, [], 'RStedman', ldap_fields)
      expect_ldap(:query_ldap_by_mail, [], 'RStedman@psu.edu', ldap_fields)
      expect(subject.count).to eq(1)
      is_expected.to eq([{ id: '', given_name: '', surname: '', email: "RStedman@psu.edu", affiliation: [], displayname: "" }])
    end
  end
end
