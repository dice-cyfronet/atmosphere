require 'spec_helper'

describe HttpMappingProxyConfGenerator do

  before :each do
    @generator = HttpMappingProxyConfGenerator.new
  end

  describe "#new" do
    it "creates a new proxy conf generator" do
      expect(@generator).to be_an_instance_of HttpMappingProxyConfGenerator
    end    
  end

  describe "#run" do

    # This one will have VMs assigned
    let!(:cs1) { create(:compute_site) }

    # This one will be left empty
    let!(:cs2) { create(:compute_site) }

    # CS2 will have:
    # - one standard appliance (1 VM, 1 appliance)
    # - one shared appliance (1 VM, many appliances)
    # - one scalable appliance (many VMs, 1 appliance)

    # let's start with the simple stuff. Spawn some ApplianceTypes:
    let!(:appl_type1) { create(:appliance_type)}
    p "Appliance type name: #{appl_type1.name}"
     
    # spawn appliance of type appl_type1
    let!(:appl1) { create(:appliance, appliance_type: appl_type1)}
    p "Appliance type name: #{appl1.appliance_type.name}"

    
    vm1 = VirtualMachine.create
    vm1.compute_site = cs1
     
    appl1.virtual_machines << vm1
      
    
    it "generates proxy configuration" do

      expect(cs1).to be_an_instance_of ComputeSite
      expect(cs2).to be_an_instance_of ComputeSite
     

      #expect(appl1.virtual_machines.length).to eql 1

      p "CS 1 id: #{cs1.id}"         
      
      conf1 = @generator.run(cs1.id)
      p "Configuration 1: #{conf1.to_s}"         
      
    end
  end

  

  # context 'new appliance created' do
# 
    # let!(:wf) { create(:workflow_appliance_set) }
    # let!(:wf2) { create(:workflow_appliance_set) }
# 
    # context 'shareable appliance type' do
      # let!(:shareable_appl_type) { create(:shareable_appliance_type) }
      # let!(:tmpl_of_shareable_at) { create(:virtual_machine_template, appliance_type: shareable_appl_type)}
# 
      # context 'vm cannot be reused' do
# 
        # it 'instantiates a new vm if there are no vms at all' do
          # tmpl_of_shareable_at
          # appl = Appliance.create(appliance_set: wf, appliance_type: shareable_appl_type, appliance_configuration_instance: create(:appliance_configuration_instance))
          # vms = VirtualMachine.all
          # expect(vms.size).to eql 1
          # vm = vms.first
          # expect(vm.appliances.size).to eql 1
          # expect(vm.appliances).to include appl
        # end
# 
        # context 'max appl number equal one' do
          # let(:config_inst) { create(:appliance_configuration_instance) }
#           
          # before do
            # Air.config.optimizer.stub(:max_appl_no).and_return 1
          # end
# 
          # it 'instantiates a new vm if already running vm cannot accept more load' do
            # appl1 = Appliance.create(appliance_set: wf, appliance_type: shareable_appl_type, appliance_configuration_instance: config_inst)
            # appl2 = Appliance.create(appliance_set: wf2, appliance_type: shareable_appl_type, appliance_configuration_instance: config_inst)
# 
            # vms = VirtualMachine.all
            # expect(vms.size).to eql 2
            # appl1.reload
            # appl2.reload
            # expect(appl1.virtual_machines.size).to eql 1
            # expect(appl2.virtual_machines.size).to eql 1
            # vm1 = appl1.virtual_machines.first
            # vm2 = appl2.virtual_machines.first
            # expect(vm1 == vm2).to be_false
          # end
        # end
# 
      # end
# 
      # context 'vm can be reused' do
# 
        # it 'reuses available vm' do
          # tmpl_of_shareable_at
          # config_inst = create(:appliance_configuration_instance)
          # appl1 = Appliance.create(appliance_set: wf, appliance_type: shareable_appl_type, appliance_configuration_instance: config_inst)
          # appl2 = Appliance.create(appliance_set: wf2, appliance_type: shareable_appl_type, appliance_configuration_instance: config_inst)
          # # expect(ApplianceSet.all.size).to eql 2 # WTF?
          # vms = VirtualMachine.all
          # expect(vms.size).to eql 1
          # vm = vms.first
          # expect(vm.appliances.size).to eql 2
          # expect(vm.appliances).to include(appl1, appl2)
        # end
# 
      # end
    # end
# 
    # context 'not shareable appliance type' do
      # let!(:not_shareable_appl_type) { create(:not_shareable_appliance_type) }
      # let!(:tmpl_of_not_shareable_at) { create(:virtual_machine_template, appliance_type: not_shareable_appl_type)}
      # it 'instantiates a new vm although vm with given conf is already running' do
        # tmpl_of_not_shareable_at
        # config_inst = create(:appliance_configuration_instance)
        # appl1 = Appliance.create(appliance_set: wf, appliance_type: not_shareable_appl_type, appliance_configuration_instance: config_inst)
        # appl2 = Appliance.create(appliance_set: wf2, appliance_type: not_shareable_appl_type, appliance_configuration_instance: config_inst)
        # vms = VirtualMachine.all
        # expect(vms.size).to eql 2
        # appl1.reload
        # appl2.reload
        # expect(appl1.virtual_machines.size).to eql 1
        # expect(appl2.virtual_machines.size).to eql 1
        # vm1 = appl1.virtual_machines.first
        # vm2 = appl2.virtual_machines.first
        # expect(vm1 == vm2).to be_false
      # end
# 
    # end
#  end
end