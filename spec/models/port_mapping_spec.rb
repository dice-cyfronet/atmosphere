# == Schema Information
#
# Table name: port_mappings
#
#  id                       :integer          not null, primary key
#  public_ip                :string(255)      not null
#  source_port              :integer          not null
#  port_mapping_template_id :integer          not null
#  virtual_machine_id       :integer          not null
#  created_at               :datetime
#  updated_at               :datetime
#

require 'spec_helper'

describe PortMapping do

  expect_it { to validate_presence_of :public_ip }
  expect_it { to validate_presence_of :source_port }
  expect_it { to validate_presence_of :virtual_machine }
  expect_it { to validate_presence_of :port_mapping_template }

  expect_it { to belong_to :virtual_machine }
  expect_it { to belong_to :port_mapping_template }

  expect_it { to validate_numericality_of :source_port }
  expect_it { should_not allow_value(-1).for(:source_port) }

  it 'calls remove port mapping method of Dnat Wrangler service when it is destroyed' do
    wrg = double('wrangler')
    expect(wrg).to receive(:remove_port_mapping).with(subject)
    DnatWrangler.stub(:instance).and_return(wrg)
    subject.destroy
  end

end
