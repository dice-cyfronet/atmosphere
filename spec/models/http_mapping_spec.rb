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
#  compute_site_id          :integer          not null
#  monitoring_status        :string(255)      default("pending")
#

require 'rails_helper'

describe HttpMapping do
  it { should validate_presence_of :url }
  it { should validate_presence_of :application_protocol }

  it { should ensure_inclusion_of(:application_protocol).in_array(%w(http https)) }

  it 'should set proper default values' do
    expect(subject.application_protocol).to eql 'http'
    expect(subject.url).to eql ''
  end

  it { should belong_to :appliance }
  it { should validate_presence_of :appliance }

  it { should belong_to :port_mapping_template }
  it { should validate_presence_of :port_mapping_template }

  describe 'redirus worker jobs' do
    subject { build(:http_mapping) }
    before do
      allow(subject).to receive(:appliance_id).and_return(1)
    end

    context 'on destroy' do
      it 'removes http redirection from redirus' do
        subject.run_callbacks(:destroy)

        expect(Redirus::Worker::RmProxy).to have_enqueued_job(proxy_name, subject.application_protocol)
      end

      it 'removes custom redirectoin from redirus' do
        subject.custom_name = 'custom_name'
        subject.run_callbacks(:destroy)

        expect(Redirus::Worker::RmProxy).to have_enqueued_job(
          'custom_name', subject.application_protocol)
      end
    end

    context 'when updating proxy' do
      before do
        subject.port_mapping_template.target_port = 80
      end

      it 'does not add redirection when no workers' do
        subject.custom_name = 'custom_name'
        subject.update_proxy

        expect(Redirus::Worker::AddProxy).to_not have_enqueued_job
      end

      it 'adds http redirection into redirus' do
        vm1 = build(:virtual_machine, state: :active, ip: '10.100.2.3')
        vm2 = build(:virtual_machine, state: :build, ip: '10.100.1.1')
        vm3 = build(:virtual_machine, state: :active, ip: nil)
        vm4 = build(:virtual_machine, state: :active, ip: '10.100.2.4')
        subject.appliance.virtual_machines = [vm1, vm2, vm3, vm4]

        subject.update_proxy

        expect(Redirus::Worker::AddProxy).to have_enqueued_job(proxy_name, match_array(['10.100.2.3:80', '10.100.2.4:80']), subject.application_protocol, [])
      end

      it 'adds custom redirection into redirus' do
        vm1 = build(:virtual_machine, state: :active, ip: '10.100.2.3')
        subject.appliance.virtual_machines = [vm1]
        subject.custom_name = 'custom_name'

        subject.update_proxy

        expect(Redirus::Worker::AddProxy).to have_enqueued_job(
          'custom_name', match_array(['10.100.2.3:80']),
          subject.application_protocol, [])
      end

      it 'adds http redirection with properties' do
        vm1 = build(:virtual_machine, state: :active, ip: '10.100.2.3')
        subject.appliance.virtual_machines = [vm1]
        properties = subject.port_mapping_template.port_mapping_properties
        properties.build(key: 'k1', value: 'v1')
        properties.build(key: 'k2', value: 'v2')

        subject.update_proxy

        expect(Redirus::Worker::AddProxy).to have_enqueued_job(proxy_name, ['10.100.2.3:80'], subject.application_protocol, match_array(['k1 v1', 'k2 v2']))
      end

      it 'removes http redirection when no workers' do
        subject.custom_name = 'custom_name'
        subject.update_proxy

        expect(Redirus::Worker::RmProxy).to have_enqueued_job(
          proxy_name, subject.application_protocol)

        expect(Redirus::Worker::RmProxy).to have_enqueued_job(
          'custom_name', subject.application_protocol)
      end
    end

    it 'removes old custom redirection and adds new one' do
      mapping = create(:http_mapping)
      mapping.update_column(:custom_name, 'old-custom-name')
      vm1 = build(:virtual_machine, state: :active, ip: '10.100.2.3')
      mapping.appliance.virtual_machines = [vm1]

      mapping.custom_name = 'new-custom-name'
      mapping.save

      expect(Redirus::Worker::RmProxy).to have_enqueued_job(
        'old-custom-name', subject.application_protocol)
      expect(Redirus::Worker::AddProxy).to have_enqueued_job(
        'new-custom-name',
        match_array(["10.100.2.3:#{mapping.port_mapping_template.target_port}"]),
        subject.application_protocol, [])
    end
  end

  it 'generates custom url' do
    hm = create(:http_mapping,
      custom_name: 'custom',
      base_url: 'http://base.url')

    expect(hm.custom_url).to eq 'http://custom.base.url'
  end

  it 'slugify custom name' do
    hm = create(:http_mapping, custom_name: 'my_custom name..')

    expect(hm.custom_name).to eq 'my-custom-name'
  end

  def proxy_name
    "#{subject.port_mapping_template.service_name}-1"
  end
end
