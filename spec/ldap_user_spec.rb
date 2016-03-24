# frozen_string_literal: true
require 'spec_helper'

describe LdapDisambiguate::LdapUser, type: :model do
  describe '#directory_attributes' do
    let(:cn) { ['CAROLYN A COLE'] }
    let(:dn) { ['CAROLYN A COLE'] }
    let(:entry) do
      entry = Net::LDAP::Entry.new
      entry['dn'] = ['uid=cam156,dc=psu,edu']
      entry['cn'] = ['CAROLYN A COLE']
      entry
    end
    context 'LDAP behaves' do
      before do
        expect(Hydra::LDAP).to receive(:get_user).and_return([entry]) if in_travis
      end
      it 'returns user attributes from LDAP' do
        result = described_class.directory_attributes('cam156', ['cn'])
        expect(result.first['cn']).to eq(cn)
      end
    end

    context 'LDAP miss behaves' do
      before do
        filter = Net::LDAP::Filter.eq('uid', 'cam156')
        allow(Hydra::LDAP).to receive(:get_user).twice.with(filter, ['cn']).and_return([entry])
        # get unwilling the first run through
        expect(Hydra::LDAP.connection).to receive(:get_operation_result).once.and_return(OpenStruct.new(code: 53, message: 'Unwilling'))
        # get success the second run through which is two calls and one more in the main code
        expect(Hydra::LDAP.connection).to receive(:get_operation_result).once.and_return(OpenStruct.new(code: 0, message: 'sucess'))
      end
      #
      it 'returns true after failing and sleeping once' do
        expect(described_class).to receive(:sleep).with(1.0)
        result = described_class.directory_attributes('cam156', ['cn'])
        expect(result.first['cn']).to eq(cn)
      end
    end
  end

  describe '#query_ldap_by_name_or_id' do
    let(:name_part) { 'cam' }
    let(:filter) { Net::LDAP::Filter.construct("(& (| (uid=#{name_part}* ) (givenname=#{name_part}*) (sn=#{name_part}*)) (| (eduPersonPrimaryAffiliation=STUDENT) (eduPersonPrimaryAffiliation=FACULTY) (eduPersonPrimaryAffiliation=STAFF) (eduPersonPrimaryAffiliation=EMPLOYEE))))") }
    let(:results) do
      [
        Net::LDAP::Entry.new('uid=cam156,dc=psu,dc=edu').tap do |e|
          e[:uid] = ['cam156']
          e[:displayname] = ['CAROLYN A COLE']
        end,
        Net::LDAP::Entry.new('uid=gmc8,dc=psu,dc=edu').tap do |e|
          e[:uid] = ['gmc8']
          e[:displayname] = ['GABRIELA M CAMPUSANO']
        end,
        Net::LDAP::Entry.new('uid=jtc152,dc=psu,dc=edu').tap do |e|
          e[:uid] = ['jtc152']
          e[:displayname] = ['J TODD CAMPBELL']
        end
      ]
    end
    let(:attrs) { %w(uid displayname) }

    before do
      expect(Hydra::LDAP).to receive(:get_user).with(filter, attrs).and_return(results) if in_travis
      allow(Hydra::LDAP.connection).to receive(:get_operation_result).and_return(OpenStruct.new(code: 0, message: 'Success')) if in_travis
    end
    it 'returns a list or people' do
      expect(described_class.query_ldap_by_name_or_id('cam')).to include({ id: 'cam156', text: 'CAROLYN A COLE (cam156)' },
                                                                         { id: 'gmc8', text: 'GABRIELA M CAMPUSANO (gmc8)' },
                                                                         id: 'jtc152', text: 'J TODD CAMPBELL (jtc152)')
    end
  end

  describe '#query_ldap_by_name' do
    context 'when known user' do
      let(:first_name) { 'Carolyn Ann' }
      let(:last_name) { 'Cole' }
      let(:first_name_parts) { %w(Carolyn Ann) }
      let(:filter) { Net::LDAP::Filter.construct("(& (& (givenname=#{first_name_parts[0]}*) (givenname=* #{first_name_parts[1]}*) (sn=#{last_name})) (| (eduPersonPrimaryAffiliation=STUDENT) (eduPersonPrimaryAffiliation=FACULTY) (eduPersonPrimaryAffiliation=STAFF) (eduPersonPrimaryAffiliation=EMPLOYEE) (eduPersonPrimaryAffiliation=RETIREE) (eduPersonPrimaryAffiliation=EMERITUS) (eduPersonPrimaryAffiliation=MEMBER)))))") }
      let(:attrs) { [:uid, :givenname, :sn, :mail, :eduPersonPrimaryAffiliation] }

      let(:results) do
        [
          Net::LDAP::Entry.new('uid=cam156,dc=psu,dc=edu').tap do |e|
            e[:uid] = ['cam156']
            e[:givenname] = ['CAROLYN A']
            e[:sn] = 'COLE'
            e[:mail] = ['cam156@psu.edu']
          end
        ]
      end
      before do
        expect(Hydra::LDAP).to receive(:get_user).with(filter, attrs).and_return(results)
        allow(Hydra::LDAP.connection).to receive(:get_operation_result).and_return(OpenStruct.new(code: 0, message: 'Success'))
      end
      it 'returns a list or people' do
        expect(described_class.query_ldap_by_name(first_name, last_name)).to eq([{ id: 'cam156', given_name: 'CAROLYN A', surname: 'COLE', email: 'cam156@psu.edu', affiliation: [] }])
      end
    end
  end
end
