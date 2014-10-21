module Atmosphere::UserExt
  extend ActiveSupport::Concern

  included do
    include Atmosphere::TokenAuthenticatable
  end
end