# == Schema Information
#
# Table name: security_proxies
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  payload    :text
#  created_at :datetime
#  updated_at :datetime
#

require 'rails_helper'

describe Atmosphere::SecurityProxy do
  it { should have_and_belong_to_many :users }
  it { should validate_presence_of :name }
  it { should validate_uniqueness_of :name }
  it { should validate_presence_of :payload }
  it { should have_many :appliance_types }
  it { should have_many(:dev_mode_property_sets).dependent(:nullify) }

  it 'validates correct name' do
    should allow_value('comp_lex/na-me.properties').for(:name)
    should_not allow_value('wrong\\path').for(:name)
    should_not allow_value('wrong//path').for(:name)
    should_not allow_value('/wrong/path').for(:name)
    should_not allow_value('wrong/path/').for(:name)
  end
end
