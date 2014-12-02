# == Schema Information
#
# Table name: appliance_types
#
#  id                 :integer          not null, primary key
#  name               :string(255)      not null
#  description        :text
#  shared             :boolean          default(FALSE), not null
#  scalable           :boolean          default(FALSE), not null
#  visible_to         :string(255)      default("owner"), not null
#  preference_cpu     :float
#  preference_memory  :integer
#  preference_disk    :integer
#  security_proxy_id  :integer
#  user_id            :integer
#  created_at         :datetime
#  updated_at         :datetime
#  metadata_global_id :string(255)
#

require 'rails_helper'

describe Atmosphere::ApplianceType do

  subject { FactoryGirl.create(:appliance_type) }

  it { should be_valid }

  it { should validate_presence_of :name }
  it { should validate_presence_of :visible_to }

  it { should validate_uniqueness_of :name }

  it { should validate_inclusion_of(:visible_to).in_array(%w(owner developer all)) }

  it { should have_db_index(:name).unique(true) }

  [:preference_memory, :preference_disk, :preference_cpu].each do |attribute|
    it { should validate_numericality_of attribute }
    it { should_not allow_value(-1).for(attribute) }
  end


  it 'should set proper default values' do
    expect(subject.visible_to).to eql 'owner'
    expect(subject.shared).to eql false
    expect(subject.scalable).to eql false
  end

  it { should belong_to :author }
  it { should have_many :appliances }
  it { should have_many(:port_mapping_templates).dependent(:destroy) }
  it { should have_many(:appliance_configuration_templates).dependent(:destroy) }
  it { should have_many(:virtual_machine_templates) }

  context 'has virtual_machine_templates or appliances (aka "is used")' do
    let(:appliance_type) { create(:appliance_type) }
    let(:user)  { create(:user) }
    let(:appliance_set) { create(:appliance_set, user: user) }
    let!(:appliance) { create(:appliance, appliance_set: appliance_set, appliance_type: appliance_type) }

    it 'is valid' do
      expect(appliance_type).to be_valid
      expect(appliance_type.appliances).not_to be_empty
    end

    it 'has a proper dependencies detection' do
      expect(appliance_type.has_dependencies?).to be_truthy
    end

    it 'is not destroyable without force' do
      appliance_type.destroy
      expect(appliance_type.errors).not_to be_empty
    end
  end

  describe '#create_from' do
    let(:dev_set) { create(:dev_appliance_set) }
    let(:at) { create(:appliance_type) }
    let(:appl) { create(:appliance, appliance_type: at, appliance_set: dev_set) }
    let(:dev_props) { appl.dev_mode_property_set }

    it 'creates appliance type from appliance' do
      at = Atmosphere::ApplianceType.create_from(appl)
      expect(at.name).to eq(dev_props.name)
      expect(at.description).to eq(dev_props.description)
      expect(at.shared).to eq(dev_props.shared)
      expect(at.scalable).to eq(dev_props.scalable)
      expect(at.preference_cpu).to eq(dev_props.preference_cpu)
      expect(at.preference_memory).to eq(dev_props.preference_memory)
      expect(at.preference_disk).to eq(dev_props.preference_disk)
    end

    let(:overwrite) do
      {
        name: 'my name',
        description: 'desc',
        scalable: true,
        preference_memory: 1024,
        appliance_id: 23
      }
    end

    it 'overwrite data from appliance' do
      at = Atmosphere::ApplianceType.create_from(appl, overwrite)
      expect(at.name).to eq(overwrite[:name])
      expect(at.description).to eq(overwrite[:description])
      expect(at.scalable).to eq(overwrite[:scalable])
      expect(at.preference_memory).to eq(overwrite[:preference_memory])
    end

    context 'when port mappings, endpoints, properties defined' do
      let(:endpoint1) { build(:endpoint) }
      let(:endpoint2) { build(:endpoint) }

      let(:port_mapping_property1) { build(:pmt_property) }
      let(:port_mapping_property2) { build(:pmt_property) }

      let(:port_mapping1) { create(:port_mapping_template,
          endpoints: [endpoint1, endpoint2],
          port_mapping_properties: [
            port_mapping_property1,
            port_mapping_property2
          ]
        )
      }

      let(:port_mapping2) { create(:port_mapping_template) }

      let(:at_with_pmt) { create(:filled_appliance_type,
          port_mapping_templates: [port_mapping1, port_mapping2]
        )
      }

      let(:appl_with_pmt) { create(:appliance, appliance_type: at_with_pmt, appliance_set: dev_set) }
      let(:dev_props_with_pmt) { appl.dev_mode_property_set }

      it 'creates pmt, endpoints, properties copy' do
        at = Atmosphere::ApplianceType.create_from(appl_with_pmt, overwrite)
        expect(at.port_mapping_templates.length).to eq 2
        expect(at.port_mapping_templates[0].endpoints.length).to eq 2
        expect(at.port_mapping_templates[0].port_mapping_properties.length).to eq 2

        expect(at.port_mapping_templates[1].endpoints.length).to eq 0
        expect(at.port_mapping_templates[1].port_mapping_properties.length).to eq 0
      end
    end

    context 'when AT has appliance configuration templates' do
      let(:act1) { build(:appliance_configuration_template, name: 'act1') }
      let(:act2) { build(:appliance_configuration_template, name: 'act2') }

      before do
        at.appliance_configuration_templates << [act1, act2]
        appl.reload
      end

      it 'copies initial configuration templates' do
        at = Atmosphere::ApplianceType.create_from(appl, overwrite)

        init_confs = at.appliance_configuration_templates.sort {|x,y| x.name <=> y.name}

        expect(init_confs.size).to eq 2
        expect(init_confs[0].name).to eq act1.name
        expect(init_confs[0].payload).to eq act1.payload
        expect(init_confs[1].name).to eq act2.name
        expect(init_confs[1].payload).to eq act2.payload
      end
    end
  end





  describe 'destroy object and relation to VMT' do
    let(:vmt1) { create(:virtual_machine_template) }
    let(:vmt2) { create(:virtual_machine_template) }
    let!(:at) { create(:appliance_type, virtual_machine_templates: [vmt1, vmt2]) }

    it 'removes all assigned virtual machine templates' do
      expect {
        at.destroy
      }.to change { Atmosphere::VirtualMachineTemplate.count }.by(-2)
    end

    it 'does not remove VMT when removed from relation' do
      expect {
        at.virtual_machine_templates = [ vmt1 ]
      }.to change { Atmosphere::VirtualMachineTemplate.count }.by(0)
    end
  end

  it 'allow to be started only on active compute site' do
    active_cs = create(:compute_site, active: true)
    inactive_cs = create(:compute_site, active: false)
    active_vmt = create(:virtual_machine_template, compute_site: active_cs)
    inactive_vmt = create(:virtual_machine_template, compute_site: inactive_cs)
    at = create(:appliance_type,
      virtual_machine_templates: [active_vmt, inactive_vmt])

    expect(at.compute_sites).to eq [active_cs]
  end

  context '#appropriate_for?' do
    it 'does not allow to use dev appliance in prod appliance set' do
      at, as = at_and_as(:developer, :portal)
      dev_as = build(:appliance_set, appliance_set_type: :development)

      expect(at.appropriate_for?(as)).to be_falsy
      expect(at.appropriate_for?(dev_as)).to be_truthy
    end

    it 'owner at appropriate only for owner' do
      at, as = at_and_as(:owner, :portal)
      user = build(:user)
      at.author = user
      as.user = user
      other_user_as = create(:appliance_set)

      expect(at.appropriate_for?(as)).to be_truthy
      expect(at.appropriate_for?(other_user_as)).to be_falsy
    end

    def at_and_as(at_type, as_type)
      at = build(:appliance_type, visible_to: at_type)
      as = build(:appliance_set, appliance_set_type: as_type)

      [at, as]
    end
  end

  context '::version' do
    it 'returns 0 when no VMT assigned' do
      at = create(:appliance_type)

      expect(at.version).to eq 0
    end

    it 'calculates higher version' do
      at = create(:appliance_type)
      create(:virtual_machine_template, appliance_type: at)
      create(:virtual_machine_template, appliance_type: at)

      expect(at.version).to eq 2
    end
  end
end
