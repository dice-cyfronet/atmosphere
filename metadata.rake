import 'Rakefile'


task purge_metadata_registry: :environment do

  puts "PURGING METADATA REGISTRY. Env = #{Rails.env}."

  global_ids = MetadataRepositoryClient.instance.get_active_global_ids
  global_ids.each do |metadata_global_id|
    MetadataRepositoryClient.instance.purge_metadata_key(metadata_global_id)
    puts metadata_global_id
  end
end


task clean_metadata_registry: :environment do

  puts "CLEANING METADATA REGISTRY. Env = #{Rails.env}."

  if Rails.env.development?
    puts 'NOT ALLOWED ON DEVELOPMENT. Exiting.'
    exit 1
  end

  if Rails.env.production?
    global_ids = MetadataRepositoryClient.instance.get_active_global_ids
    puts global_ids
    ApplianceType.transaction do
      ApplianceType.where(visible_to: ['all','developer']).all.each do |at|
        if at.metadata_global_id
          puts "Removing ApplianceType #{at.name}."
          if MetadataRepositoryClient.instance.delete_metadata(at)
            at.update_column(:metadata_global_id, nil)
          end
        end
      end
    end
  end
end


task populate_metadata_registry: :environment do

  puts "POPULATING METADATA REGISTRY. Env = #{Rails.env}."

  if Rails.env.development?
    puts 'NOT ALLOWED ON DEVELOPMENT. Exiting.'
    exit 1
  end

  if Rails.env.production?

    current_global_ids = MetadataRepositoryClient.instance.get_active_global_ids
    ApplianceType.transaction do
      ApplianceType.where(visible_to: ['all','developer']).all.each do |at|
        if at.metadata_global_id and current_global_ids.include?(at.metadata_global_id)
          puts "Updating ApplianceType #{at.name}."
          MetadataRepositoryClient.instance.update_appliance_type at
        else
          puts "Publishing or re-publishing ApplianceType #{at.name}."
          mgid = MetadataRepositoryClient.instance.publish_appliance_type at
          at.update_column(:metadata_global_id, mgid) if mgid
        end
      end

    end
  end
end
