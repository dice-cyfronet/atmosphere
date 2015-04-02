require 'fog/google/models/compute/flavor'
require 'fog/google/models/compute/image'
require 'fog/google/models/compute/servers'
require 'fog/google/models/compute/server'
require 'fog/google/models/compute/disk'

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

        def id
          name
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

        def id
          name
        end
      end

      class Servers
        ZONE = 'us-central1-a'

        alias_method :create_orig, :create
        def create(params)
          # Cyrrently hardcoded, in the feature it can be moved somewhere,
          # for example into compute site configuration?
          params[:zone] = ZONE

          # Such user account with root privilage will be created on
          # spawned machine. In the feature we can use user account here,
          # but we need to answer the quesion what about production run, where
          # machine can be shared amoud the users.
          params[:username] = 'atmosphere'

          disk = create_disk(params)
          params[:disk] = disk.get_object(true, true,
                                          'created_by_atmosphere', true)

          server = nil
          if params[:atmo_user_key]
            Tempfile.open('userkey') do |f|
              server = start_server(params.merge(key_path: f.path))
            end
          else
            server = start_server(params)
          end

          server
        end

        def destroy(id_at_site)
          service.delete_server(id_at_site, ZONE)
        end

        private

        def create_disk(params)
          disk_params = {
            name: params[:name],
            # think about taking it from flavor or user requirement.
            # Flavor disk is currently set to 0 so this also need to be
            # rethinked.
            size_gb: 10,
            zone_name: params[:zone],
            source_image: params[:image_id],
            autoDelete: true
          }
          disk = service.disks.create(disk_params)
          disk.wait_for { disk.ready? }

          disk
        end

        def start_server(params)
          server_params = {
            name: params[:name],
            machine_type: params[:flavor_id],
            zone_name: params[:zone],
            username: params[:username],
            public_key_path: params[:key_path],
            disks: [params[:disk]]
          }

          create_orig(server_params)
        end
      end

      class Server
        def image_id
          disk_id = bootable_disk['source'].split('/').last
          service.disks.get(disk_id).image_id
        end

        def task_state
        end

        def flavor_id
          machine_type.split('/').last
        end

        def created
          Time.parse(creation_timestamp)
        end

        def id
          name
        end

        def stop
          raise Atmosphere::UnsupportedException,
                'Fog des not support google compute stop action'
        end

        def pause
          raise Atmosphere::UnsupportedException,
                'Google compute des not support pause action'
        end

        def suspend
          raise Atmosphere::UnsupportedException,
                'Google compute des not support suspend action'
        end

        def start
          raise Atmosphere::UnsupportedException,
                'Fog des not support google compute start action'
        end

        private

        def bootable_disk
          disks.detect { |d| d['boot'] }
        end
      end

      class Disk
        def image_id
          source_image.split('/').last
        end
      end

      class Real
        def create_tags_for_vm(server_id, tags_map)
          server = servers.get(server_id)
          existing_tags = server.tags['items'] || []

          clean = lambda { |s| s.downcase.gsub(/[^a-z0-9]/, '-') }
          tags = tags_map.map { |k, v| "#{clean.call(k)}-#{clean.call(v)}" }

          server.set_tags(existing_tags + tags)
        end
      end
    end
  end
end
