require 'fog/google/models/compute/flavor'
require 'fog/google/models/compute/image'

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

      class Image
        def architecture
          'x86_64'
        end

        alias_method :status_orig, :status
        def status
          s = status_orig

          if s == 'READY'
            'active'
          else
            s
          end
        end

        def tags
          {}
        end
      end
    end
  end
end
