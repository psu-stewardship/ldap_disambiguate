# frozen_string_literal: true
require 'spec_helper'

describe LdapDisambiguate::Name do
  let(:ldap_fields) { [:uid, :givenname, :sn, :mail, :eduPersonPrimaryAffiliation, :displayname] }
  subject { described_class.disambiguate(name) }
  before do
    allow(LdapDisambiguate::LdapUser).to receive(:directory_attributes).with(name, ldap_fields).and_return([]) if in_travis
    expect(LdapDisambiguate::LdapUser).not_to receive(:get_users) if in_travis
  end

  context 'when we have a normal name' do
    let(:name) { 'Thompson, Britta M' }
    let(:response) { format_name_response('bmt13', 'BRITTA MAY', 'THOMPSON', 'FACULTY') }
    it 'finds the user' do
      expect_ldap(:query_ldap_by_name, response, 'Britta M', 'Thompson')
      expect(subject.count).to eq(1)
    end
  end

  context 'when we have an id' do
    let(:name) { 'cam156' }
    let(:response) { format_name_response('cam156', 'CAROLYN A', 'COLE') }
    it 'finds the ids' do
      expect_ldap(:directory_attributes, response, name, ldap_fields)
      expect(LdapDisambiguate::LdapUser).not_to receive(:query_ldap_by_name)
      expect(subject.count).to eq(1)
    end
  end

  context 'when we have multiple combined with an and' do
    let(:name) { 'Carolyn Cole and Adam Wead' }
    let(:response1) { format_name_response('cam156', 'CAROLYN A', 'COLE') }
    let(:response2) { format_name_response('agw13', 'ADAM GARNER', 'WEAD') }
    it 'finds both users' do
      expect_ldap(:query_ldap_by_name, response1, 'Carolyn', 'Cole')
      expect_ldap(:query_ldap_by_name, response2, 'Adam', 'Wead')
      is_expected.to eq([response1.first, response2.first])
    end
  end

  context 'when we have initials for first name' do
    let(:name) { 'A.S. Ostrowski' }
    let(:response) { format_name_response('aso118', 'ALEX S', 'OSTROWSKI', 'STUDENT') }
    it 'finds the user' do
      expect_ldap(:query_ldap_by_name, response, 'A S', 'Ostrowski')
      is_expected.to eq(response)
    end
  end

  context 'when we have multiple results' do
    let(:name) { 'Jane Doe' }
    let(:response) do
      [format_name_response('jjd1', 'Jane', 'Doe').first,
       format_name_response('jod1', 'Jane Other', 'Doe').first]
    end
    it 'finds the user' do
      expect_ldap(:query_ldap_by_name, response, 'Jane', 'Doe')
      is_expected.to eq([])
    end
  end

  context 'when the user has many titles' do
    let(:name) { 'Nicole Seger, MSN, RN, CPN' }
    let(:response) { format_name_response('nas150', 'NICOLE A', 'SEGER') }
    it 'finds the user' do
      expect_ldap(:query_ldap_by_name, [], 'MSN', 'Nicole Seger')
      expect_ldap(:query_ldap_by_name, [], 'Nicole Seger, MSN,', 'RN, CPN')
      expect_ldap(:query_ldap_by_name, response, 'Nicole', 'Seger')
      is_expected.to eq(response)
    end
  end

  context 'when the user has a title first' do
    let(:name) { 'MSN Deb Cardenas' }
    let(:response) { format_name_response('dac40', 'DEBORAH A.', 'CARDENAS') }
    it 'finds the user' do
      expect_ldap(:query_ldap_by_name, [], 'MSN Deb', 'Cardenas')
      expect_ldap(:query_ldap_by_name, response, 'Deb', 'Cardenas')
      is_expected.to eq(response)
    end
  end

  context 'when the user has strange characters' do
    let(:name) { 'Patricia Hswe *' }
    let(:response) { format_name_response('pmh22', 'PATRICIA M', 'HSWE', 'FACULTY') }
    it 'cleans the name' do
      expect_ldap(:query_ldap_by_name, response, 'Patricia', 'Hswe')
      is_expected.to eq(response)
    end
  end

  context 'when the user has an apostrophy' do
    let(:name) { "Anthony R. D'Augelli" }
    let(:response) { format_name_response('ard', 'ANTHONY RAYMOND', "D'AUGELLI", 'FACULTY') }
    it 'finds the user' do
      expect_ldap(:query_ldap_by_name, response, 'Anthony R', "D'Augelli")
      is_expected.to eq(response)
    end
  end

  context 'when the user has many names' do
    let(:name) { 'ALIDA HEATHER DOHN ROSS' }
    let(:response) { format_name_response('hdr10', 'ALIDA HEATHER', 'DOHN ROSS') }
    it 'finds the user' do
      expect_ldap(:query_ldap_by_name, [], 'ALIDA HEATHER DOHN', 'ROSS')
      expect_ldap(:query_ldap_by_name, [], 'DOHN', 'ROSS')
      expect_ldap(:query_ldap_by_name, response, 'ALIDA HEATHER', 'DOHN ROSS')
      is_expected.to eq(response)
    end
  end

  context 'when the user has additional information' do
    let(:name) { 'Cole, Carolyn (Kubicki Group)' }
    let(:response) { format_name_response('cam156', 'CAROLYN A', 'COLE') }
    it 'cleans the name' do
      expect_ldap(:query_ldap_by_name, response, 'Carolyn', 'Cole')
      is_expected.to eq(response)
    end
  end

  context 'when the user has an email in thier name' do
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

    context 'when the email is their id' do
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
end
