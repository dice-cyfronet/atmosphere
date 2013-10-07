module VphHelper
  def vph_login_enabled?
    Devise.omniauth_providers.include?(:vph)
  end
end
