admin = User.create(login: 'admin', full_name: 'Root Admiński z Superuserów', email: 'admin@localhost.pl', password: 'airtraffic123', password_confirmation: 'airtraffic123', authentication_token: 'secret', roles: [:admin, :developer])

ApplianceSet.create(name: 'test appliance set', user: admin)

ApplianceType.create(name: 'Ubuntu Ruliez, hy hy')