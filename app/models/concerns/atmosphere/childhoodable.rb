module Atmosphere
  module Childhoodable
    extend ActiveSupport::Concern

    def old?
      created_at < Air.config.
        cloud_object_protection_time.seconds.ago
    end
  end
end
