# == Schema Information
#
# Table name: http_mappings
#
#  id                       :integer          not null, primary key
#  application_protocol     :string(255)      default("http"), not null
#  url                      :string(255)      default(""), not null
#  appliance_id             :integer
#  port_mapping_template_id :integer
#  created_at               :datetime
#  updated_at               :datetime
#

require 'spec_helper'

describe HttpMapping do
  expect_it { to validate_presence_of :url }
  expect_it { to validate_presence_of :application_protocol }

  expect_it { to ensure_inclusion_of(:application_protocol).in_array(%w(http https)) }

  it 'should set proper default values' do
    expect(subject.application_protocol).to eql 'http'
    expect(subject.url).to eql ''
  end

  expect_it { to belong_to :appliance }
  expect_it { to validate_presence_of :appliance }

  expect_it { to belong_to :port_mapping_template }
  expect_it { to validate_presence_of :port_mapping_template }

  describe 'redirus worker jobs' do
    subject { build(:http_mapping) }

    context 'on destroy' do
      it 'removes http redirection from redirus' do
        subject.run_callbacks(:destroy)

        expect(Redirus::Worker::RmProxy).to have_enqueued_job(subject.port_mapping_template.service_name, subject.application_protocol)
      end
    end

    context 'when updating proxy' do
      before do
        subject.port_mapping_template.target_port = 80
      end

      it 'does not add redirection when no workers' do
        subject.update_proxy

        expect(Redirus::Worker::AddProxy).to have(0).jobs
      end

      it 'adds http redirection into redirus' do
        vm1 = build(:virtual_machine, state: :active, ip: '10.100.2.3')
        vm2 = build(:virtual_machine, state: :build, ip: '10.100.1.1')
        vm3 = build(:virtual_machine, state: :active, ip: nil)
        vm4 = build(:virtual_machine, state: :active, ip: '10.100.2.4')
        subject.appliance.virtual_machines = [vm1, vm2, vm3, vm4]

        subject.update_proxy

        expect(Redirus::Worker::AddProxy).to have_enqueued_job(subject.port_mapping_template.service_name, ['10.100.2.3:80', '10.100.2.4:80'], subject.application_protocol, [])
      end

      it 'adds http redirection with properties' do
        vm1 = build(:virtual_machine, state: :active, ip: '10.100.2.3')
        subject.appliance.virtual_machines = [vm1]
        properties = subject.port_mapping_template.port_mapping_properties
        properties.build(key: 'k1', value: 'v1')
        properties.build(key: 'k2', value: 'v2')

        subject.update_proxy

         expect(Redirus::Worker::AddProxy).to have_enqueued_job(subject.port_mapping_template.service_name, ['10.100.2.3:80'], subject.application_protocol, ['k1 v1', 'k2 v2'])
      end
    end
  end
end
