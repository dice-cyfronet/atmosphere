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

require 'rails_helper'

describe PortMapping do
  it { should validate_presence_of :public_ip }
  it { should validate_presence_of :source_port }
  it { should validate_presence_of :virtual_machine }
  it { should validate_presence_of :port_mapping_template }

  it { should belong_to :virtual_machine }
  it { should belong_to :port_mapping_template }

  it { should validate_numericality_of :source_port }
  it { should_not allow_value(-1).for(:source_port) }

  it 'calls remove port mapping method of Dnat Wrangler service when it is destroyed' do
    pm = create(:port_mapping)
    wrg = double('wrangler')
    allow(pm.virtual_machine.compute_site)
      .to receive(:dnat_client).and_return(wrg)

    expect(wrg).to receive(:remove_port_mapping).with(pm)

    pm.destroy
  end
end
