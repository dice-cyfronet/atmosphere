module MasterInterfaceHelper
  def mi_login_enabled?
    Devise.omniauth_providers.include?(:vph)
  end
end
