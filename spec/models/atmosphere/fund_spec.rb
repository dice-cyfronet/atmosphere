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

  describe '#unsupported_compute_sites' do

    subject { build(:fund) }

    let!(:cs1) { create(:compute_site) }
    let!(:cs2) { create(:compute_site) }
    let!(:cs3) { create(:compute_site) }

    it 'lists all sites when none is assigned' do
      expect(subject.unsupported_compute_sites).to match_array [cs2, cs1, cs3]
    end

    it 'lists all correct unassigned sites' do
      # NOTE I know the below seems strange but otherwise rspec tricked me :(
      csf = Atmosphere::ComputeSiteFund.new(compute_site: cs1)
      subject.compute_site_funds << csf
      subject.save
      expect(subject.unsupported_compute_sites).to match_array [cs2, cs3]
    end

    it 'returns empty array when all sites are assigned' do
      [cs1, cs2, cs3].each do |cs|
        csf = Atmosphere::ComputeSiteFund.new(compute_site: cs)
        subject.compute_site_funds << csf
      end
      subject.save
      expect(subject.unsupported_compute_sites).to match_array []
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
