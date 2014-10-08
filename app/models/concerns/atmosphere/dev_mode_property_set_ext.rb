module Atmosphere::DevModePropertySetExt
  extend ActiveSupport::Concern

  module ClassMethods
    def copy_additional_params
      []
    end
  end
end