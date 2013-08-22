admin = User.create(login: 'admin', full_name: 'Root Admiński z Superuserów', email: 'admin@localhost.pl', password: 'airtraffic123', password_confirmation: 'airtraffic123', roles: [:admin, :developer])

ApplianceSet.create(name: 'test appliance set', context_id: '1', user: admin)

ApplianceType.create(name: 'Ubuntu Ruliez, hy hy')