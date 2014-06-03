# == Schema Information
#
# Table name: port_mapping_templates
#
#  id                       :integer          not null, primary key
#  transport_protocol       :string(255)      default("tcp"), not null
#  application_protocol     :string(255)      default("http_https"), not null
#  service_name             :string(255)      not null
#  target_port              :integer          not null
#  appliance_type_id        :integer
#  dev_mode_property_set_id :integer
#  created_at               :datetime
#  updated_at               :datetime
#

require 'spec_helper'

describe PortMappingTemplate do

  before { Fog.mock! }

  let(:dnat_client_mock) { double('dnat client') }

  subject { FactoryGirl.create(:port_mapping_template) }

  expect_it { to be_valid }

  expect_it { to validate_presence_of :service_name }
  expect_it { to validate_presence_of :target_port }
  expect_it { to validate_presence_of :application_protocol }
  expect_it { to validate_presence_of :transport_protocol }

  expect_it { to ensure_inclusion_of(:transport_protocol).in_array(%w(tcp udp)) }

  context 'if transport_protocol is tcp' do
    before { subject.stub(:transport_protocol) { 'tcp' } }
    expect_it { to ensure_inclusion_of(:application_protocol).in_array(%w(http https http_https)) }
  end

  context 'if transport_protocol is udp' do
    before { subject.stub(:transport_protocol) { 'udp' } }
    expect_it { to ensure_inclusion_of(:application_protocol).in_array(%w(none)) }
  end

  it 'should set proper default values' do
    # It seems we should use strings, not symbols here - perhaps this makes some kind of round-trip to DB?
    expect(subject.application_protocol).to eql 'http_https'
    expect(subject.transport_protocol).to eql 'tcp'
  end

  expect_it { to have_many :http_mappings }
  expect_it { to have_many(:port_mappings).dependent(:destroy) }
  expect_it { to have_many(:port_mapping_properties).dependent(:destroy) }
  expect_it { to have_many(:endpoints).dependent(:destroy) }

  expect_it { to validate_numericality_of :target_port }
  expect_it { should_not allow_value(-1).for(:target_port) }

  expect_it { to validate_uniqueness_of(:target_port).scoped_to(:appliance_type_id, :dev_mode_property_set_id) }
  expect_it { to validate_uniqueness_of(:service_name).scoped_to(:appliance_type_id, :dev_mode_property_set_id) }

  expect_it { to belong_to :appliance_type }
  expect_it { to belong_to :dev_mode_property_set }

  context 'if no appliance_type' do
    before { subject.stub(:appliance_type) { nil } }
    expect_it { to validate_presence_of(:dev_mode_property_set) }
  end

  context 'if no dev_mode_property_set' do
    before { subject.stub(:dev_mode_property_set) { nil } }
    expect_it { to validate_presence_of(:appliance_type) }
  end

  # Uncomment 2 bellow tests when this PR is acceptedhttps://github.com/thoughtbot/shoulda-matchers/pull/331 and than "belongs_to appliance_type or dev_mode_property_set" context can be removed

  # context 'if appliance_type is present' do
  #   before { subject.stub(:appliance_type_id) { 1 } }
  #   expect_it { to validate_abesence_of(:dev_mode_property_set) }
  # end

  # context 'if dev_mode_property_set is present' do
  #   before { subject.stub(:dev_mode_property_set_id) { 1 } }
  #   expect_it { to validate_abesence_of(:appliance_type) }
  # end

  context 'belongs_to appliance_type or dev_mode_property_set' do
    let(:appliance_type) { create(:appliance_type) }
    let(:dev_mode_property_set) { create(:dev_mode_property_set) }
    let(:pmt) { create(:port_mapping_template, appliance_type: appliance_type, dev_mode_property_set: nil) }
    let(:dev_pmt) { create(:port_mapping_template, appliance_type: nil, dev_mode_property_set: dev_mode_property_set) }

    it 'is valid if belongs only to appliance_type' do
      expect(pmt).to be_valid
    end

    it 'is valid if belongs only to dev_mode_property_set' do
      expect(dev_pmt).to be_valid
    end

    it 'is not valid if belongs to nothing' do
      not_belonging = build(:port_mapping_template, appliance_type: nil, dev_mode_property_set: nil)
      expect(not_belonging).to_not be_valid
    end

    it 'cannot belong int both' do
      pmt.dev_mode_property_set = dev_mode_property_set
      expect(pmt).to_not be_valid

      dev_pmt.appliance_type = appliance_type
      expect(dev_pmt).to_not be_valid
    end
  end

  context 'belongs_to appliance type that "is used"' do
    let(:appliance_type) { create(:appliance_type) }
    let(:user)  { create(:user) }
    let(:appliance_set) { create(:appliance_set, user: user) }
    let!(:appliance) { create(:appliance, appliance_set: appliance_set, appliance_type: appliance_type) }
    let(:pmt) { create(:port_mapping_template, appliance_type: appliance_type, dev_mode_property_set: nil) }

    it 'is valid' do
      expect(pmt).to be_valid
    end
  end

  context 'port mapping type' do
    context 'when http application protocol' do
      subject { create(:port_mapping_template, application_protocol: :http) }

      it 'is http redirection' do
        expect(subject.http?).to be_true
      end

      it 'is not https redirection' do
        expect(subject.https?).to be_false
      end
    end

    context 'when https application protocol' do
      subject { create(:port_mapping_template, application_protocol: :https) }

      it 'is not http redirection' do
        expect(subject.http?).to be_false
      end

      it 'is https redirection' do
        expect(subject.https?).to be_true
      end
    end

    context 'when http_https application protocol' do
      subject { create(:port_mapping_template, application_protocol: :http_https) }

      it 'is http redirection' do
        expect(subject.http?).to be_true
      end

      it 'is https redirection' do
        expect(subject.https?).to be_true
      end
    end

    context 'when none changed into http/https' do
      let(:appliance_type) { create(:appliance_type) }
      let(:port_mapping) { create(:port_mapping, virtual_machine: vm) }
      let(:pmt) { create(:port_mapping_template, appliance_type: appliance_type, dev_mode_property_set: nil, application_protocol: :none, port_mappings: [port_mapping]) }
      let(:vm) { create(:virtual_machine) }
      let!(:appliance) { create(:appliance, appliance_type: appliance_type, virtual_machines: [vm]) }

      before do
        pmt.application_protocol = :http
        dnat_client_mock.stub(:remove_port_mapping)
      end

      it 'remove dnat redirection' do
        expect {
          pmt.save
        }.to change { PortMapping.count }.by(-1)
      end
    end

    it 'does not remove dnat mapping when type none not changed', focus: true do
      allow(DnatWrangler).to receive(:new).and_return(dnat_client_mock)
      appliance_type = create(:appliance_type)
      pmt = create(:port_mapping_template, appliance_type: appliance_type, dev_mode_property_set: nil, application_protocol: :none)
      appliance = create(:appliance, appliance_type: appliance_type)
      vm = create(:virtual_machine, ip: '10.100.1.2', appliances: [appliance])
      create(:port_mapping, port_mapping_template: pmt, virtual_machine: vm)
      pmt.reload

      expect(dnat_client_mock).not_to receive(:remove_port_mapping)

      pmt.save
    end

    it 'does not add dnat mapping when type none not changed' do
      allow(DnatWrangler).to receive(:new).and_return(dnat_client_mock)
      appliance_type = create(:appliance_type)
      pmt = create(:port_mapping_template, appliance_type: appliance_type, dev_mode_property_set: nil, application_protocol: :none)
      appliance = create(:appliance, appliance_type: appliance_type)
      vm = create(:virtual_machine, ip: '10.100.1.2', appliances: [appliance])

      expect(dnat_client_mock).not_to receive(:add_dnat_for_vm)

      pmt.save
    end

    context 'when http/https changed into none' do
      before do
        DnatWrangler.stub(:new).and_return(dnat_client_mock)
        dnat_client_mock.stub(:add_dnat_for_vm).and_return([])
      end

      it 'adds dnat port mapping' do
        appliance_type = create(:appliance_type)
        pmt = create(:port_mapping_template, appliance_type: appliance_type, dev_mode_property_set: nil, application_protocol: :http)
        vm = create(:virtual_machine, ip: '10.100.1.2')
        appliance = create(:appliance, appliance_type: appliance_type, virtual_machines: [vm])

        expect(dnat_client_mock).to receive(:add_dnat_for_vm).and_return([])

        pmt.reload
        pmt.application_protocol = :none
        pmt.save
      end
    end
  end

  context 'port mappings' do

    before do
     dnat_client_mock.stub(:add_dnat_for_vm).and_return([])
    end

    let(:public_ip) { '149.156.10.135' }
    let(:public_port_1) { 34567 }
    let(:public_port_2) { 8765 }
    let(:priv_ip) { '10.1.1.1' }
    let(:appliance) { create(:appliance)}
    let!(:vm) { create(:virtual_machine, ip: priv_ip, appliances: [appliance]) }
    let(:pmt) { create(:port_mapping_template, appliance_type:appliance.appliance_type, application_protocol: :none) }
    let(:pm_1) { create(:port_mapping, port_mapping_template: pmt, virtual_machine: vm) }
    let(:pm_2) { create(:port_mapping, port_mapping_template: pmt, virtual_machine: vm) }

    context 'adds port mapping using dnat wrangler when pmt is created' do
      let(:wrg) { double('wrangler') }
      before do
        Optimizer.instance.stub(:run)
        DnatWrangler.stub(:new).and_return(dnat_client_mock)
        dnat_client_mock.stub(:add_dnat_for_vm).and_return([{port_mapping_template: PortMappingTemplate.first, virtual_machine: vm, public_ip: public_ip, source_port: public_port_1}])
      end
      let(:proto) { 'tcp' }
      let(:priv_port) { 8080 }


      it 'calls Wrangler to add port mappings to production vms associated to created port mapping template' do
        expect(dnat_client_mock).to receive(:add_dnat_for_vm)
        pmt = create(:port_mapping_template, appliance_type:appliance.appliance_type, application_protocol: :none)
      end

      it 'adds port mappings to development vms associated to created port mapping template' do
        expect(vm).to receive(:add_dnat)
        appl = create(:appl_dev_mode, virtual_machines: [vm])
        dev_mode_prop_set = create(:dev_mode_property_set, appliance: appl)
        pmt = create(:dev_port_mapping_template, dev_mode_property_set: dev_mode_prop_set)
      end

    end

    describe 'port mapping template is updated' do
      it 'creates mapping update jobs for each port mapping if target port changed' do
        dnat_client_mock.stub(:remove)
        dnat_client_mock.stub(:add_dnat_for_vm).and_return([], [])#([{port_mapping_template: pmt, virtual_machine: vm, public_ip: public_ip, source_port: public_port_1}], [{port_mapping_template: pmt, virtual_machine: vm, public_ip: public_ip, source_port: public_port_2}])
        pmt.update_attribute(:target_port, 7777)
      end

      it 'does not create mapping update jobs if target port was not changed' do
        expect(DnatWrangler).to_not receive(:remove)
        pmt.update_attribute(:service_name, 'new service name')
      end
    end
  end

  describe '#service_name' do
    context 'with spaces at the beginning and at the end' do
      subject { create(:port_mapping_template, service_name: ' with-spaces ') }

      it 'removes spaces on save' do
        expect(subject.service_name).to eq 'with-spaces'
      end
    end

    context 'with not allowed chanrs' do
      it 'sanitize name before save' do
        pmt = create(:port_mapping_template, service_name: 'a b_c!@#')

        expect(pmt.service_name).to eq 'a-b-c'
      end
    end
  end


  describe 'manage metadata' do
    let!(:endp11) { build(:endpoint, description: 'FIRST ENDP') }
    let!(:endp12) { build(:endpoint, description: 'ENDP_DESC') }
    let!(:endp21) { build(:endpoint) }
    let!(:pmt1) { build(:port_mapping_template, endpoints: [endp11, endp12]) }
    let!(:pmt2) { build(:port_mapping_template, endpoints: [endp21]) }
    let!(:pmt3) { build(:port_mapping_template) }
    let!(:pmt5) { build(:port_mapping_template) }
    let!(:complex_at) { create(:appliance_type, port_mapping_templates: [pmt1, pmt5], visible_to: :all, name: 'complex_at') }

    let!(:endp41) { build(:endpoint) }
    let!(:pmt4) { build(:port_mapping_template, endpoints: [endp41]) }
    let!(:private_complex_at) { create(:appliance_type, port_mapping_templates: [pmt4], visible_to: :owner) }

    it 'updates metadata when PMT destroyed' do
      expect(MetadataRepositoryClient.instance).to receive(:update_appliance_type).with(complex_at).twice
      pmt1.destroy
    end

    it 'updates metadata when PMT with endpoint added' do
      expect(MetadataRepositoryClient.instance).to receive(:update_appliance_type).with(complex_at)
      complex_at.port_mapping_templates << pmt2
    end

    it 'does not update metadata when empty PMT added' do
      expect(MetadataRepositoryClient.instance).not_to receive(:update_appliance_type)
      complex_at.port_mapping_templates << pmt3
    end

    it 'does not update metadata when empty PMT destroyed' do
      expect(MetadataRepositoryClient.instance).not_to receive(:update_appliance_type)
      pmt5.destroy
    end

    it 'does not update appliance metadata when not published' do
      expect(MetadataRepositoryClient.instance).not_to receive(:update_appliance_type)
      pmt4.destroy
    end

  end
end
