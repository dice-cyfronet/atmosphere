module Atmosphere
  module VphHelper
    def vphticket_login_enabled?
      Devise.omniauth_providers.include?(:vphticket)
    end
  end
end