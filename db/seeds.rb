admin = User.create(login: 'admin', full_name: 'Root Admiński z Superuserów', email: 'admin@localhost.pl', password: 'airtraffic123', password_confirmation: 'airtraffic123', authentication_token: 'secret', roles: [:admin, :developer])

as = ApplianceSet.create(name: 'test appliance set', user: admin)

at = ApplianceType.create(name: 'Ubuntu Ruliez, hy hy')

PortMappingTemplate.create(service_name: 'pmt', target_port: 1, application_protocol: 'http', transport_protocol: 'tcp', appliance_type: at)

act = ApplianceConfigurationTemplate.create(name: 'act', appliance_type: at)

aci = ApplianceConfigurationInstance.create(appliance_configuration_template: act)

Appliance.create(appliance_set: as, appliance_type: at, appliance_configuration_instance: aci)