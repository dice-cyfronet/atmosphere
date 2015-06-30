# == Schema Information
#
# Table name: funds
#
#  id                 :integer          not null, primary key
#  name               :string(255)      default("unnamed fund"), not null
#  balance            :integer          default(0), not null
#  currency_label     :string(255)      default("EUR"), not null
#  overdraft_limit    :integer          default(0), not null
#  termination_policy :string(255)      default("suspend"), not null
#

require 'rails_helper'

describe Atmosphere::Fund do

  describe '#unsupported_tenants' do

    subject { build(:fund) }

    let!(:t1) { create(:tenant) }
    let!(:t2) { create(:tenant) }
    let!(:t3) { create(:tenant) }

    it 'lists all tenants when none is assigned' do
      expect(subject.unsupported_tenants).to match_array [t2, t1, t3]
    end

    it 'lists all correct unassigned tenants' do
      # NOTE I know the below seems strange but otherwise rspec tricked me :(
      csf = Atmosphere::TenantFund.new(tenant: t1)
      subject.tenant_funds << tf
      subject.save
      expect(subject.unsupported_tenants).to match_array [t2, t3]
    end

    it 'returns empty array when all tenants are assigned' do
      [t1, t2, t3].each do |t|
        tf = Atmosphere::TenantFund.new(tenant: t)
        subject.tenant_funds << tf
      end
      subject.save
      expect(subject.unsupported_tenants).to match_array []
    end

  end

  describe '#unassigned_users' do

    subject { build(:fund) }

    let!(:u1) { create(:user) }
    let!(:u2) { create(:user) }
    let!(:u3) { create(:user) }

    it 'lists all users when no one is assigned' do
      expect(subject.unassigned_users).to match_array [u2, u3, u1]
    end

    it 'lists all correct unassigned users' do
      uf = Atmosphere::UserFund.new(user: u1)
      subject.user_funds << uf
      subject.save
      expect(subject.unassigned_users).to match_array [u3, u2]
    end

    it 'returns empty array when everybody is assigned' do
      [u1, u2, u3].each do |u|
        uf = Atmosphere::UserFund.new(user: u)
        subject.user_funds << uf
      end
      subject.save
      expect(subject.unassigned_users).to match_array []
    end

  end

end
