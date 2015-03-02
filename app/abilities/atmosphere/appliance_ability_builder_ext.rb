module Atmosphere::ApplianceAbilityBuilderExt
  extend ActiveSupport::Concern

  private

  def can_start_ext?(appl)
    true
  end
end
