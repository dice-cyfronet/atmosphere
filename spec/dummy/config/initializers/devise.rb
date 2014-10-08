Devise.setup do |config|
  Warden::Strategies.add(:token_authenticatable, Devise::Strategies::TokenAuthenticatable)

  config.warden do |manager|
    manager.intercept_401 = false
    manager.default_strategies(:scope => :user).unshift :token_authenticatable
  end
end