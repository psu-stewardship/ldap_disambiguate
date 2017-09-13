# frozen_string_literal: true
require 'spec_helper'

describe LdapDisambiguate::LdapUser, type: :model do
  describe '#directory_attributes' do
    let(:cn) { 'CAROLYN ANN COLE' }
    let(:dn) { ['CAROLYN ANN COLE'] }
    let(:entry) do
      entry = Net::LDAP::Entry.new
      entry['dn'] = ['uid=cam156,dc=psu,edu']
      entry['cn'] = ['CAROLYN ANN COLE']
      entry
    end
    context 'LDAP behaves' do
      before do
        expect(Hydra::LDAP).to receive(:get_user).and_return([entry]) if in_travis
      end
      it 'returns user attributes from LDAP' do
        result = described_class.directory_attributes('cam156', ['cn'])
        expect(result.first['cn']).to eq(cn)
        expect(Hydra::LDAP).not_to receive(:get_user)
        result = described_class.directory_attributes('cam156', ['cn'])
        expect(result.first['cn']).to eq(cn)
      end
    end

    context 'LDAP miss behaves' do
      before do
        filter = Net::LDAP::Filter.eq('uid', 'cam157')
        allow(Hydra::LDAP).to receive(:get_user).twice.with(filter, ['cn']).and_return([entry])
        # get unwilling the first run through
        expect(Hydra::LDAP.connection).to receive(:get_operation_result).once.and_return(OpenStruct.new(code: 53, message: 'Unwilling'))
        # get success the second run through which is two calls and one more in the main code
        expect(Hydra::LDAP.connection).to receive(:get_operation_result).once.and_return(OpenStruct.new(code: 0, message: 'sucess'))
      end
      #
      it 'returns true after failing and sleeping once' do
        expect(described_class).to receive(:sleep).with(1.0)
        result = described_class.directory_attributes('cam157', ['cn'])
        expect(result.first['cn']).to eq(cn)
      end
    end
  end

  describe '#query_ldap_by_name' do
    context 'when known user' do
      let(:first_name) { 'Carolyn Ann' }
      let(:last_name) { 'Cole' }
      let(:first_name_parts) { %w(Carolyn Ann) }
      let(:filter) { Net::LDAP::Filter.construct("(& (& (givenname=#{first_name_parts[0]}*) (givenname=* #{first_name_parts[1]}*) (sn=#{last_name})) (| (eduPersonPrimaryAffiliation=STUDENT) (eduPersonPrimaryAffiliation=FACULTY) (eduPersonPrimaryAffiliation=STAFF) (eduPersonPrimaryAffiliation=EMPLOYEE) (eduPersonPrimaryAffiliation=RETIREE) (eduPersonPrimaryAffiliation=EMERITUS) (eduPersonPrimaryAffiliation=MEMBER)))))") }
      let(:attrs) { [:uid, :givenname, :sn, :mail, :eduPersonPrimaryAffiliation, :displayname] }

      let(:results) do
        [
          Net::LDAP::Entry.new('uid=cam156,dc=psu,dc=edu').tap do |e|
            e[:uid] = ['cam156']
            e[:givenname] = ['CAROLYN A']
            e[:sn] = 'COLE'
            e[:mail] = ['cam156@psu.edu']
            e[:displayname] = ['CAROLYN A COLE']
          end
        ]
      end
      before do
        expect(Hydra::LDAP).to receive(:get_user).with(filter, attrs).and_return(results)
        allow(Hydra::LDAP.connection).to receive(:get_operation_result).and_return(OpenStruct.new(code: 0, message: 'Success'))
      end
      it 'returns a list or people' do
        expect(described_class.query_ldap_by_name(first_name, last_name)).to eq([{ id: 'cam156', given_name: 'CAROLYN A', surname: 'COLE', email: 'cam156@psu.edu', affiliation: [], displayname: 'CAROLYN A COLE' }])
      end
    end
  end
end
