# frozen_string_literal: true

require 'spec_helper'

describe LdapDisambiguate::Name do
  let(:ldap_fields) { %i[uid givenname sn mail eduPersonPrimaryAffiliation displayname] }
  subject { described_class.disambiguate(name) }
  before do
    allow(LdapDisambiguate::LdapUser).to receive(:directory_attributes).with(name, ldap_fields).and_return([]) if in_travis
  end

  context 'when we have a normal name' do
    let(:name) { 'Thompson, Britta M' }
    let(:response) { format_name_response('bmt13', 'BRITTA MAY', 'THOMPSON', 'FACULTY') }
    it 'finds the user' do
      expect_ldap(:query_ldap_by_name, response, 'Britta M', 'Thompson', ldap_fields)
      expect(subject.count).to eq(1)
    end
  end

  context 'when we have an id' do
    let(:name) { 'cam156' }
    let(:response) do
      resp = format_name_response('cam156', 'CAROLYN A', 'COLE')
      resp[0][:displayname] = [resp[0][:displayname]]
      resp
    end
    it 'finds the ids' do
      expect_ldap(:directory_attributes, response, name, ldap_fields)
      expect(LdapDisambiguate::LdapUser).not_to receive(:query_ldap_by_name)
      expect(subject.count).to eq(1)
    end
  end

  context 'when we have multiple combined with an and' do
    let(:name) { 'Carolyn Cole and Adam Wead' }
    let(:response1) { format_name_response('cam156', 'CAROLYN ANN', 'COLE') }
    let(:response2) { format_name_response('agw13', 'ADAM GARNER', 'WEAD') }
    it 'finds both users' do
      expect_ldap(:query_ldap_by_name, response1, 'Carolyn', 'Cole', ldap_fields)
      expect_ldap(:query_ldap_by_name, response2, 'Adam', 'Wead', ldap_fields)
      is_expected.to eq([response1.first, response2.first])
    end
  end

  context 'when we have initials for first name' do
    let(:name) { 'A.J. Ostrowski' }
    let(:response) { format_name_response('ajo5254', 'AMANDA JEAN', 'OSTROWSKI', 'STUDENT') }
    it 'finds the user' do
      expect_ldap(:query_ldap_by_name, response, 'A J', 'Ostrowski', ldap_fields)
      is_expected.to eq(response)
    end
  end

  context 'when we have multiple results' do
    let(:name) { 'C Cole' }
    let(:response) do
      [format_name_response('cac13', 'CHARLES ANDREW', 'COLE').first,
       format_name_response('cam156', 'CAROLYN A', 'COLE').first]
    end
    it 'finds the user' do
      expect_ldap(:query_ldap_by_name, response, 'C', 'Cole', ldap_fields)
      is_expected.to eq([])
    end
  end

  context 'when the user has many titles' do
    let(:name) { 'Nicole Seger, MSN, RN, CPN' }
    let(:response) { format_name_response('nas150', 'NICOLE A', 'SEGER') }
    it 'finds the user' do
      expect_ldap(:query_ldap_by_name, [], 'MSN', 'Nicole Seger', ldap_fields)
      expect_ldap(:query_ldap_by_name, [], 'Nicole Seger, MSN,', 'RN, CPN', ldap_fields)
      expect_ldap(:query_ldap_by_name, response, 'Nicole', 'Seger', ldap_fields)
      is_expected.to eq(response)
    end
  end

  context 'when the user has a title first' do
    let(:name) { 'MSN Deb Cardenas' }
    let(:response) { format_name_response('dac40', 'DEBORAH A.', 'CARDENAS') }
    it 'finds the user' do
      expect_ldap(:query_ldap_by_name, [], 'MSN Deb', 'Cardenas', ldap_fields)
      expect_ldap(:query_ldap_by_name, response, 'Deb', 'Cardenas', ldap_fields)
      is_expected.to eq(response)
    end
  end

  context 'when the user has strange characters' do
    let(:name) { 'Carolyn Cole *' }
    let(:response) { format_name_response('cam156', 'CAROLYN ANN', 'COLE', 'STAFF') }
    it 'cleans the name' do
      expect_ldap(:query_ldap_by_name, response, 'Carolyn', 'Cole', ldap_fields)
      is_expected.to eq(response)
    end
  end

  context 'when the user has an apostrophy' do
    let(:name) { "Anthony R. D'Augelli" }
    let(:response) { format_name_response('ard', 'ANTHONY RAYMOND', "D'AUGELLI", 'EMERITUS') }
    it 'finds the user' do
      expect_ldap(:query_ldap_by_name, response, 'Anthony R', "D'Augelli", ldap_fields)
      is_expected.to eq(response)
    end
  end

  context 'when the user has many names' do
    let(:name) { 'ALIDA HEATHER DOHN ROSS' }
    let(:response) { format_name_response('hdr10', 'ALIDA HEATHER', 'DOHN ROSS') }
    it 'finds the user' do
      expect_ldap(:query_ldap_by_name, [], 'ALIDA HEATHER DOHN', 'ROSS', ldap_fields)
      expect_ldap(:query_ldap_by_name, [], 'DOHN', 'ROSS', ldap_fields)
      expect_ldap(:query_ldap_by_name, response, 'ALIDA HEATHER', 'DOHN ROSS', ldap_fields)
      is_expected.to eq(response)
    end
  end

  context 'when the user has additional information' do
    let(:name) { 'Cole, Carolyn (Kubicki Group)' }
    let(:response) { format_name_response('cam156', 'CAROLYN ANN', 'COLE') }
    it 'cleans the name' do
      expect_ldap(:query_ldap_by_name, response, 'Carolyn', 'Cole', ldap_fields)
      is_expected.to eq(response)
    end
  end

  context 'when the user has an email in thier name' do
    context 'when the email is not their id' do
      let(:name) { 'Barbara I. Dewey a bdewey@psu.edu' }
      let(:response) { format_name_response('bid1', 'BARBARA IRENE', 'DEWEY') }
      it 'does not find the user' do
        expect_ldap(:directory_attributes, [], 'Barbara I. Dewey a bdewey@psu.edu', ldap_fields)
        expect_ldap(:directory_attributes, [], 'bdewey', ldap_fields)
        expect_ldap(:query_ldap_by_mail, response, 'bdewey@psu.edu', ldap_fields)
        is_expected.to eq([{ id: "bid1", given_name: "BARBARA IRENE", surname: "DEWEY", email: "bid1@psu.edu", affiliation: ["STAFF"], displayname: "BARBARA IRENE DEWEY" }])
        # is_expected.to eq([{ id: '', given_name: '', surname: '', email: 'bdewey@psu.edu', affiliation: [], displayname: '' }])
      end
    end

    context 'when the email is their id' do
      let(:name) { 'sjs230@psu.edu' }
      let(:response) { format_ldap_response('sjs230', 'SARAH J', 'STAGER') }
      it 'finds the user' do
        expect_ldap(:directory_attributes, [], 'sjs230@psu.edu', ldap_fields)
        expect_ldap(:directory_attributes, response, 'sjs230', ldap_fields)
        expect(subject.count).to eq(1)
      end
    end

    context 'when the email is their id' do
      let(:name) { 'sjs230@psu.edu, cam156@psu.edu' }
      let(:response1) { format_ldap_response('sjs230', 'SARAH J', 'STAGER') }
      let(:response2) { format_ldap_response('cam156', 'CAROLYN A', 'cole') }
      it 'finds the user' do
        expect_ldap(:directory_attributes, [], 'sjs230@psu.edu, cam156@psu.edu', ldap_fields)
        expect_ldap(:directory_attributes, response1, 'sjs230', ldap_fields)
        expect_ldap(:directory_attributes, response2, 'cam156', ldap_fields)
        expect(subject.count).to eq(2)
      end
    end

    context "when name is weird" do
      let(:name) { 'Brandon Hunt (thesis: Keith Wilson)' }
      it 'it does not error' do
        expect(subject.count).to eq(0)
      end
    end

    context "when name is weird" do
      let(:name) { "Kenan Ünlü" }
      it 'it does not error' do
        expect_ldap(:directory_attributes, [], 'Kenan Ünlü', ldap_fields)
        expect_ldap(:query_ldap_by_name, [], 'Kenan', 'nl', ldap_fields)
        expect(subject.count).to eq(0)
      end
    end

    context "when name is Shih", unless: in_travis do
      let(:name) { "Dr. Patrick C. Shih" }
      it 'it does not error' do
        puts subject
        expect(subject.count).to eq(0)
      end
    end
  end
end
