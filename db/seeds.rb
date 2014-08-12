#encoding: utf-8

admin = User.create(login: 'admin', full_name: 'Admin', email: 'admin@example.com', password: 's3cr3t!!!', password_confirmation: 's3cr3t!!!', authentication_token: 'change_me', roles: [:admin, :developer])