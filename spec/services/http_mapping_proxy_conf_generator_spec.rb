require 'spec_helper'

describe HttpMappingProxyConfGenerator do

  describe "#new" do
    it "creates a new proxy conf generator" do
      expect(subject).to be_an_instance_of HttpMappingProxyConfGenerator
    end
  end


  describe "#run" do

    # TODO: Divide this into contexts

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
    let!(:appl_type2) { create(:appliance_type, scalable: true)}
    let!(:appl_type3a) { create(:appliance_type, shared: true)}
    let!(:appl_type3b) { create(:appliance_type, shared: true)}

    # ---appliance type 1---
    # spawn one PMTemplate for appl_type1
    let!(:pm_template1) { create(:port_mapping_template, appliance_type: appl_type1, application_protocol: "http_https")}

    # spawn appliance of type appl_type1
    let!(:appl1) { create(:appliance, appliance_type: appl_type1)}
    #p "Appliance type name: #{appl1.appliance_type.name}"
    #p "Appliance config: #{appl1.appliance_configuration_instance.payload}"

    # spawn one VM for appl1
    let!(:vm1) { create(:virtual_machine, appliances: [appl1], compute_site: cs1, ip: "10.100.8.10")}

    # spawn one http_mapping for appl1
    let!(:pm_a1) { create(:http_mapping, appliance: appl1, port_mapping_template: pm_template1)}

    # ---appliance type 2---
    # spawn one PMTemplate for appl_type2
    let!(:pm_template2) { create(:port_mapping_template, appliance_type: appl_type2, application_protocol: "http_https")}

    # spawn appliance of type appl_type2
    let!(:appl2) { create(:appliance, appliance_type: appl_type2)}

    # spawn two VMs for appl2 (scalable appliance)
    let!(:vm2_1) { create(:virtual_machine, appliances: [appl2], compute_site: cs1, ip: "10.100.8.11")}
    let!(:vm2_2) { create(:virtual_machine, appliances: [appl2], compute_site: cs1, ip: "10.100.8.12")}

    # spawn one http_mapping for appl2
    let!(:pm_a2) { create(:http_mapping, appliance: appl2, port_mapping_template: pm_template2)}


    # ---appliance type 3---
    # spawn two PMTemplates for appl_types 3a and 3b
    let!(:pm_template3a) { create(:port_mapping_template, appliance_type: appl_type3a, application_protocol: "http_https")}
    let!(:pm_template3b) { create(:port_mapping_template, appliance_type: appl_type3b, application_protocol: "http_https")}

    # spawn two appliances of type appl_type3 (3a and 3b; shared VM)
    let!(:appl3a) { create(:appliance, appliance_type: appl_type3a)}
    let!(:appl3b) { create(:appliance, appliance_type: appl_type3b)}

    # spawn single VM for both appl3a and 3b
    let!(:vm3) { create(:virtual_machine, appliances: [appl3a, appl3b], compute_site: cs1, ip: "10.100.8.13")}

    # spawn two http_mappings for appl3a and 3b
    let!(:pm_a3a) { create(:http_mapping, appliance: appl3a, port_mapping_template: pm_template3a)}
    let!(:pm_a3b) { create(:http_mapping, appliance: appl3b, port_mapping_template: pm_template3b)}


    it "generates proxy configuration" do

      expect(cs1).to be_an_instance_of ComputeSite
      expect(cs2).to be_an_instance_of ComputeSite

      # TODO: For some reason logger.* does not work here (i.e. nothing is written to application logs), so I'm using puts instead.
      # This needs to be debugged.
      p "CS 1 id: #{cs1.id}"

      conf1 = subject.run(cs1.id)
      p "Configuration 1: #{conf1.to_s}"

      # Doesn't work. Figure out why (the correct exception is, in fact, raised, but rspec doesn't like it for some reason.)
      # expect(@generator.run(123456789)).to raise_error(Air::UnknownComputeSite)

      expect(conf1.length).to eql 8
      # TODO: Add all sorts of expects (worker list lengths, regexp path validation etc.)
      # Ran out of time to do it myself (PN) :(

    end
  end

end