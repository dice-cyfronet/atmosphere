require 'fog/rackspace/models/compute_v2/image'
require 'fog/rackspace/models/compute_v2/flavor'
require 'fog/rackspace/models/compute_v2/server'

module Fog
  module Compute
    class RackspaceV2
      class Image
        def architecture
          'x86_64'
        end

        def tags
          metadata.to_hash
        end

        def status
          state
        end
      end

      class Flavor
        def supported_architectures
          'x86_64'
        end
      end

      class Server
        def task_state
          state_ext
        end

        def stop
          raise Atmosphere::UnsupportedException,
                'Rackspace des not support stop action'
        end

        def pause
          raise Atmosphere::UnsupportedException,
                'Rackspace des not support pause action'
        end

        def suspend
          raise Atmosphere::UnsupportedException,
                'Rackspace des not support suspend action'
        end

        def start
          raise Atmosphere::UnsupportedException,
                'Rackspace des not support start action'
        end
      end

      class Real
        def save_template(instance_id, tmpl_name)
          resp = create_image(instance_id, tmpl_name)
          if [200, 201, 202].include?(resp.status)
            image_id(resp)
          else
            raise "Failed to save vm #{instance_id} as template"
          end
        end

        def create_tags_for_vm(server_id, tags_map)
          set_metadata('servers', server_id, tags_map)
        end

        def import_key_pair(name, public_key)
          create_keypair(name, public_key: public_key)
        end

        def delete_key_pair(id_at_site)
          delete_keypair(id_at_site)
        end

        private

        def image_id(resp)
          match = resp.headers['Location'].match(/.*\/(.*)\z/)
          match && match[1]
        end
      end
    end
  end
end
