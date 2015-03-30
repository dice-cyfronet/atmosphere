require 'fog/google/models/compute/flavor'

module Fog
  module Compute
    class Google
      class Flavor
        def vcpus
          guest_cpus
        end

        def ram
          memory_mb
        end

        def disk
          image_space_gb || 0
        end

        def supported_architectures
          'x86_64'
        end
      end
    end
  end
end
