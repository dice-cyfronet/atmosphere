require 'fog/google/models/compute/flavor'
require 'fog/google/models/compute/image'
require 'fog/google/models/compute/images'
require 'fog/google/models/compute/servers'
require 'fog/google/models/compute/server'
require 'fog/google/models/compute/disk'
require 'fog/google/models/compute/snapshot'

module Fog
  module Compute
    class Google
      module Snapshotable
        def snapshot?(id_at_site)
          id_at_site.start_with?('snapshot:')
        end

        def real_id(id_at_site)
          match = id_at_site.match(/\A.*:(.*)\z/)
          match ? match[1] : id_at_site
        end
      end

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
          s == 'READY' ? 'active' : s
        end

        def tags
          {}
        end

        def id
          "image:#{name}"
        end
      end

      class Images
        include Snapshotable

        alias_method :all_orig, :all
        def all(_params = nil)
          all_orig + service.snapshots.all
        end

        alias_method :destroy_orig, :destroy
        def destroy(id_at_site)
          id = real_id(id_at_site)
          if snapshot?(id_at_site)
            service.snapshots.destroy(id)
          else
            destroy_orig(id)
          end
        end
      end

      class Snapshot
        def id
          "snapshot:#{name}"
        end

        def architecture
          'x86_64'
        end

        alias_method :status_orig, :status
        def status
          s = status_orig
          s == 'READY' ? 'active' : s
        end

        def tags
          {}
        end
      end

      class Servers
        include Snapshotable

        ZONE = 'us-central1-a'

        alias_method :create_orig, :create
        def create(params)
          # Currently hardcoded, in the feature it can be moved somewhere,
          # for example into tenant configuration?
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
            key_file = Tempfile.open('userkey') do |f|
              f.write(params[:atmo_user_key].public_key)
              f
            end
            server = start_server(params.merge(key_path: key_file.path))
          else
            server = start_server(params)
          end

          if params[:user_data]
            server.set_metadata(user_data: params[:user_data])
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
            # rethought.
            size_gb: 10,
            zone_name: params[:zone],
            autoDelete: true
          }

          id = real_id(params[:image_id])
          if snapshot?(params[:image_id])
            disk_params[:sourceSnapshot] = id
          else
            disk_params[:source_image] = id
          end

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
            disks: [params[:disk]],
            network: params[:network]
          }

          create_orig(server_params)
        end
      end

      class Server
        def image_id
          service.disks.get(bootable_disk_name).image_id
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
                'Fog does not support google compute stop action'
        end

        def pause
          raise Atmosphere::UnsupportedException,
                'Google compute does not support pause action'
        end

        def suspend
          raise Atmosphere::UnsupportedException,
                'Google compute does not support suspend action'
        end

        def start
          raise Atmosphere::UnsupportedException,
                'Fog does not support google compute start action'
        end

        def bootable_disk
          disks.detect { |d| d['boot'] }
        end

        def bootable_disk_name
          bootable_disk['source'].split('/').last
        end
      end

      class Disk
        def image_id
          if source_image
            "image:#{source_image.split('/').last}"
          elsif source_snapshot
            "image:#{source_snapshot.split('/').last}"
          end
        end
      end

      class Real
        def create_tags_for_vm(server_id, tags_map)
          server = servers.get(server_id)

          existing_tags = server.tags['items'] || []
          tags = tags_map.map { |k, v| "#{clean(k)}-#{clean(v)}" }

          server.set_tags(existing_tags + tags)
        end

        def import_key_pair(_id_at_site, _public_key)
          # DO NOTHING since key is injected while starting VM
        end

        def delete_key_pair(_id_at_site)
          # DO NOTHING since key is injected while starting VM
        end

        def save_template(instance_id, tmpl_name)
          name = clean(tmpl_name)
          instance = servers.get(instance_id)

          insert_snapshot(instance.bootable_disk_name,
                          'us-central1-a', nil,
                          { 'name' => name })

          "snapshot:#{name}"
        end

        private

        def clean(str)
          str.downcase.gsub(/[^a-z0-9]/, '-')
        end
      end
    end
  end
end
