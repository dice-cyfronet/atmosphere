module Atmosphere
  module Childhoodable
    extend ActiveSupport::Concern

    def old?
      created_at < Atmosphere.cloud_object_protection_time.seconds.ago
    end
  end
end
