Atmosphere::OSFamily.find_or_create_by(name: 'Windows')
Atmosphere::OSFamily.find_or_create_by(name: 'Linux')

unless Rails.env.test?
  Atmosphere::User.find_or_initialize_by(login: 'admin').tap do |u|
    u.full_name = 'Admin'
    u.email = 'admin@example.com'
    u.password = 's3cr3t!!!'
    u.password_confirmation = 's3cr3t!!!'
    u.roles = [:admin, :developer]

    u.save!
  end
end
