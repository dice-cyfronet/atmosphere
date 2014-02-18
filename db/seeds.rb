#encoding: utf-8

admin = User.create(login: 'admin', full_name: 'Root Admiński z Superuserów', email: 'admin@localhost.pl', password: 'airtraffic123', password_confirmation: 'airtraffic123', authentication_token: 'secret', roles: [:admin, :developer])

user = User.create(login: 'user', full_name: 'User', email: 'user@localhost.pl', password: 'user1234', password_confirmation: 'user1234', authentication_token: 'secret2', roles: [:developer])

as = ApplianceSet.create(name: 'test appliance set', user: admin)

at = ApplianceType.create(name: 'Ubuntu 12.04 LTS 64b V3')

at2 = ApplianceType.create(name: 'Ubuntu 12.04 LTS 64b at Amazon')

ApplianceType.create(name: 'PLD v.1 super-stable at-last-we-are-secure-edition Remix 2006 with all repos blocked (no poldek release)')

PortMappingTemplate.create(service_name: 'pmt', target_port: 1, application_protocol: 'http', transport_protocol: 'tcp', appliance_type: at)
pmt2 = PortMappingTemplate.create(service_name: 'pmt2', target_port: 144, application_protocol: 'none', transport_protocol: 'udp', appliance_type: at)

Endpoint.create(description: 'No descriptor endpoint', endpoint_type: 'ws', port_mapping_template: pmt2)


act = ApplianceConfigurationTemplate.create(name: 'act', appliance_type: at)

act2 = ApplianceConfigurationTemplate.create(name: 'act2', appliance_type: at2)

aci = ApplianceConfigurationInstance.create(appliance_configuration_template: act, payload: 'Init conf 1')

aci2 = ApplianceConfigurationInstance.create(appliance_configuration_template: act2, payload: 'Init conf 2')

Appliance.create(appliance_set: as, appliance_type: at, appliance_configuration_instance: aci)

Appliance.create(appliance_set: as, appliance_type: at2, appliance_configuration_instance: aci2)

cs = ComputeSite.create(site_id: "cyfronet-folsom", name: "Cyfronet", location: "Cracow", site_type: "private", technology: "openstack")

cs2 = ComputeSite.create(site_id: "amazon-eu", name: "Amazon EU", location: "Ireland", site_type: "public", technology: "aws")

VirtualMachineTemplate.create(id_at_site: "addc2222-9632-468e-8b78-18c74d9df6ef", name: "Ubuntu 12.04 LTS 64b V3", state: "active", compute_site: cs, appliance_type: at)
VirtualMachineTemplate.create(id_at_site: "ami-ce7b6fba", name: "Ubuntu 12.04 LTS 64b", state: "active", compute_site: cs2, appliance_type: at2)