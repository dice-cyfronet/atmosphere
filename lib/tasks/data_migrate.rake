import 'Rakefile'

MIGRATE_USERS = true
MIGRATE_APPLIANCE_TYPES = true
MIGRATE_WORKFLOWS = true
MIGRATE_DEVELOPMENT = true

task :monkey => :environment do

  require 'optimizer'
  require 'dnat_wrangler'
  require 'proxy_conf_worker'

  class Optimizer
    def run(hint); end
  end

  class ProxyConfWorker
    def self.regeneration_required(cs); end
  end

  class DnatWrangler
    def remove_dnat_for_vm(*args); end
    def remove_port_mapping(*args); end
    def add_dnat_for_vm(*args) []; end
    def remove(*args); end
  end
end


def build_port_mapping_template(old_port_mapping, old_enpoints)
  puts " --- Creating new Port Mapping Template #{old_port_mapping['service_name']}:#{old_port_mapping['port']}."
  pmt = PortMappingTemplate.new(service_name: old_port_mapping['service_name'], target_port: old_port_mapping['port'])
  pmt.application_protocol = (old_port_mapping['http'] ? (old_port_mapping['https'] ? 'http_https' : 'http') : (old_port_mapping['https'] ? 'https' : 'none'))
  # You should set either AT id or DMPS id outside of this method
  pmt.appliance_type_id = nil
  pmt.dev_mode_property_set_id = nil
  old_enpoints.each do |old_endpoint|
    puts " ----- Adding a new Endpoint #{old_endpoint['invocation_path']}."
    new_endpoint = Endpoint.new(name: old_endpoint['invocation_path'], description: old_endpoint['description'], descriptor: old_endpoint['descriptor'], endpoint_type: old_endpoint['endpoint_type'].downcase, invocation_path: old_endpoint['invocation_path'], port_mapping_template: pmt)
    pmt.endpoints << new_endpoint
  end
  #puts " --- Is new PMT valid?: #{pmt.valid?}."
  #p pmt.errors
  pmt
end


task :data_migrate_1 => :monkey do
  Fog.mock!

  puts "STARTING MIGRATION PROCEDURE. Env = #{Rails.env}."

  data = JSON.parse IO.read('/home/atmosphere/air1_migration_space/air1_data.json')

  puts "\n - USERS"

  User.transaction do
  data['users'].each_with_index do |old_user, i|

    user = User.where(login: old_user['vph_username']).first_or_initialize do |new_user|
      puts " - Creating new user #{new_user.login}."
      new_user.roles = [:developer]
      new_user.email = "#{i}@vph-share.eu"
      new_user.password = 'phony-pass'
    end

    puts " - Created or found user #{user.login}."

    if user.user_keys.empty? and old_user['user_keys'].present?
      puts " --- Copying #{old_user['user_keys'].size} User Keys for user #{user.login}."
      user.user_keys = old_user['user_keys'].map{|old_user_key| UserKey.new(name: old_user_key['name'], public_key: old_user_key['public_key'], user: user)}
      user.user_keys = user.user_keys.delete_if do |uk|
        puts " ----- [WARNING] Rejecting user key #{uk.name} since it is not valid. Messages: [#{uk.errors.full_messages.join(', ')}]." unless uk.valid?
        !uk.valid?
      end
      puts " --- Copied key names: [#{user.user_keys.map(&:name).join(', ')}]."
    end

    puts " --- Is new user valid?: #{user.valid?}."
   
    ['security_proxies','security_policies'].each do |model|
      old_user_sps = data[model].select{|sp| sp['owners'].include? old_user['id'].to_s}
      new_relation = user.send(model)
      if new_relation.empty? and old_user_sps.present?
        puts " --- Found #{old_user_sps.size} #{model.titleize} belonging to user #{user.login}. Processing."
        old_user_sps.each do |old_sp|
          sp = model.classify.constantize.where(name: old_sp['name']).first_or_initialize do |new_sp|
            new_sp.payload = old_sp['payload']
          end
          if sp.valid? 
            new_relation << sp
          else
            puts " ----- [WARNING] Rejecting #{model.titleize} #{sp.name} since it is not valid. Messages: [#{sp.errors.full_messages.join(', ')}]."
          end
        end
      end
    end

    user.save
    puts " --- Is new user valid?: #{user.valid?}."

    #exit if old_user_security_proxies.present?

  end if MIGRATE_USERS
  end # of transaction
  puts " - Bypassing Users setup." unless MIGRATE_USERS


  puts "\n - APPLIANCE TYPES"
  old_template_vms = data['vms'].select{|vm| vm['state'] == 'template'}

  appliance_configurtation_template_map = {}

  ApplianceType.transaction do
  data['production_appliance_types'].each_with_index do |old_appliance_type, i|

    appliance_type = ApplianceType.where(name: old_appliance_type['name']).first_or_initialize do |new_appliance_type|
      puts " - Creating new production Appliance Type #{old_appliance_type['name']}."
      new_appliance_type.description = old_appliance_type['description']
      new_appliance_type.shared = old_appliance_type['shared']
      new_appliance_type.scalable = old_appliance_type['scalable']
      new_appliance_type.visible_to = (old_appliance_type['published'] ? :all : :developer)
      unless old_appliance_type['appliance_preferences'].nil?
        puts " --- Copying Appliance Preferences directly into ApplianceType."
        new_appliance_type.preference_memory = old_appliance_type['appliance_preferences']['memory']
        new_appliance_type.preference_memory = nil if old_appliance_type['appliance_preferences']['memory'] == 0
        new_appliance_type.preference_disk = old_appliance_type['appliance_preferences']['disk']
        new_appliance_type.preference_disk = nil if old_appliance_type['appliance_preferences']['disk'] == 0
        new_appliance_type.preference_cpu = old_appliance_type['appliance_preferences']['cpu']
        new_appliance_type.preference_cpu = nil if old_appliance_type['appliance_preferences']['cpu'] == 0.0
      end
      unless old_appliance_type['author'].nil?
        new_appliance_type.author = User.find_by(login: data['users'].detect{|u| u['id'] == old_appliance_type['author']}['vph_username'])
        if new_appliance_type.author
          puts " --- Setting Appliance Type author to #{new_appliance_type.author.login}."
        else
          puts " --- [ERROR] Appliance Type author #{old_appliance_type['author']} not found among the users!"
        end
      else
        puts " --- Appliance Type #{new_appliance_type.name} does not have an author."
      end
      unless old_appliance_type['proxy_conf_name'].nil?
        new_appliance_type.security_proxy = SecurityProxy.find_by(name: old_appliance_type['proxy_conf_name'])
        if new_appliance_type.security_proxy
          puts " --- Appliance Type Security Proxy set to #{new_appliance_type.security_proxy.name}."
        else
          puts " --- [ERROR] Security Proxy of name [#{old_appliance_type['proxy_conf_name']}] not found in the new database."
        end
      end

      puts " --- Is new appliance type valid?: #{new_appliance_type.valid?}."
      new_appliance_type.save
    
      old_appliance_type['port_mappings'].each do |old_port_mapping|
        new_appliance_type.port_mapping_templates << build_port_mapping_template(old_port_mapping,
          old_appliance_type['endpoints'].present? ? old_appliance_type['endpoints'].select{|endp| endp['port'] == old_port_mapping['port']} : [])
      end

      data['appliance_configurations'].select{|ac| ac['appliance_type'] == old_appliance_type['id']}.each do |old_appliance_configuration|
        puts " --- Adding Appliance Configuration [#{old_appliance_configuration['config_name']}]."
        #new_appliance_type.appliance_configuration_templates << ApplianceConfigurationTemplate.new(name: old_appliance_configuration['config_name'], payload: old_appliance_configuration['config_file'])
        new_appliance_type.appliance_configuration_templates.build(name: old_appliance_configuration['config_name'], payload: old_appliance_configuration['config_file'])
      end

      old_templates = old_template_vms.select{|t| t['appliance_type'] == old_appliance_type['id']}
      if old_templates.present?
        puts " --- Found #{old_templates.size} old VM templates set to this Appliance Type."
        old_templates.each do |old_template|
          vmt_id = old_template['vms_id'].gsub('cyfronet-folsom-tmpl-','').gsub('amazon-tmpl-','')
          new_virtual_machine_template = VirtualMachineTemplate.find_by(id_at_site: vmt_id)
          if new_virtual_machine_template
            new_virtual_machine_template.appliance_type = new_appliance_type
            new_virtual_machine_template.managed_by_atmosphere = true
            new_virtual_machine_template.instances.each do |vm|
              vm.managed_by_atmosphere = true
              vm.save
            end
            new_virtual_machine_template.save
            puts " ----- Updated Virtual Machine Template #{new_virtual_machine_template.id_at_site} to Appliance Type [#{new_appliance_type.name}]."
          else
            puts " ----- [WARNING] Virtual Machine Template of id #{vmt_id} not found in new Air2; probably already removed from the cloud."
          end
        end
      end

    end
    puts " --- Is new appliance type valid?: #{appliance_type.valid?}."
    appliance_type.save

  end if MIGRATE_APPLIANCE_TYPES
  end # of transaction
  puts " - Bypassing Appliance Types setup." unless MIGRATE_APPLIANCE_TYPES


  modes = []
  modes += ['portal','workflow'] if MIGRATE_WORKFLOWS
  modes << 'development' if MIGRATE_DEVELOPMENT
  modes.each do |mode|
    puts "\n#{mode} MODE"
    User.transaction do
      data['users'].each_with_index do |old_user, i|
        user = User.find_by(login: old_user['vph_username'])
        puts "\n - Recreating #{mode} workflows for user #{user.login}." 
        old_user['workflows'].select{|wf| wf['workflow_type'] == mode}.each do |old_workflow|

          puts " --- Copying Workflow of type [#{old_workflow['workflow_type']}] for user #{user.login}."
          new_appliance_set = ApplianceSet.new(name: old_workflow['name'], priority: old_workflow['priority'], appliance_set_type: old_workflow['workflow_type'], user: user)

          unless old_workflow['vms_ids'].nil?
            old_workflow['vms_ids'].each do |old_vms_id|
              old_vms = data['vms'].detect{|vm| vm['vms_id'] == old_vms_id}
              if mode == 'development'
                puts " ----- Searching for 'original', non-development Appliance Type for development Appliance Type #{old_vms['appliance_type']}."
                old_development_appliance_type = data['development_appliance_types'].detect{|dat| dat['id'] == old_vms['appliance_type']}
                if old_development_appliance_type
                  puts " ----- Found development Appliance Type #{old_development_appliance_type['name']}."
                  old_appliance_type = data['production_appliance_types'].detect{|pat| pat['id'] == old_development_appliance_type['original_appliance']}
                  puts " ----- Found original, non-development Appliance Type #{old_appliance_type['name']}."
                else
                  puts " ----- [WARNING] Old development appliance type not found, trying to find it among the production appliance types."
                  old_appliance_type = data['production_appliance_types'].detect{|dat| dat['id'] == old_vms['appliance_type']}
                  old_development_appliance_type = old_appliance_type
                end
                raise Exception.new(" ----- [ERROR] Appliance Type #{old_vms['appliance_type']} not found either in development or in production appliance types!") unless old_appliance_type
                appliance_type = ApplianceType.find_by(name: old_appliance_type['name'])
                if appliance_type.appliance_configuration_templates.present?
                  appliance_configuration_template = appliance_type.appliance_configuration_templates.first
                else
                  raise Exception.new(" ----- [ERROR] The original Appliance Type has no Appliance Configuration templates present!")
                end
              else
                old_appliance_configuration = data['appliance_configurations'].detect{|ac| ac['id'] == old_vms['configuration']}
                appliance_configuration_template = ApplianceConfigurationTemplate.find_by(name: old_appliance_configuration['config_name'])
              end
              appliance_configuration_instance = ApplianceConfigurationInstance.where(appliance_configuration_template: appliance_configuration_template).first_or_initialize do |new_appliance_configuration_instance|
                puts " ----- Creating new Appliance Configuration Instance for Template #{appliance_configuration_template.name}."
                new_appliance_configuration_instance.create_payload(appliance_configuration_template.payload, {})
              end
              puts " ----- Creting a new Appliance."

              new_appliance = Appliance.new(appliance_set: new_appliance_set, appliance_type: appliance_configuration_template.appliance_type, appliance_configuration_instance: appliance_configuration_instance, state: :satisfied)
              unless old_vms['user_key'].nil?
                old_user_key = data['users'].detect{|u| u['vph_username'] == user.login}['user_keys'].detect{|uk| uk['id'] == old_vms['user_key']}
                user_key = user.user_keys.find_by(name: old_user_key['name'])
                if user_key
                  puts " ------- Found user Key #{user_key.name} and adding it to Appliance'"
                  new_appliance.user_key = user_key
                else
                  raise Exception.new(" ------- [ERROR] no user key of name #{old_user_key['name']} found!")
                end
              end

              if mode == 'development'
                new_dev_mode_property_set = DevModePropertySet.new(name: old_development_appliance_type['name'])
                new_dev_mode_property_set.description = old_development_appliance_type['description']
                new_dev_mode_property_set.shared = old_development_appliance_type['shared']
                new_dev_mode_property_set.scalable = old_development_appliance_type['scalable']
                unless old_development_appliance_type['appliance_preferences'].nil?
                  puts " --- Copying Appliance Preferences directly into ApplianceType."
                  new_dev_mode_property_set.preference_memory = old_development_appliance_type['appliance_preferences']['memory']
                  new_dev_mode_property_set.preference_memory = nil if old_development_appliance_type['appliance_preferences']['memory'] = 0
                  new_dev_mode_property_set.preference_disk = old_development_appliance_type['appliance_preferences']['disk']
                  new_dev_mode_property_set.preference_disk = nil if old_development_appliance_type['appliance_preferences']['disk'] = 0
                  new_dev_mode_property_set.preference_cpu = old_development_appliance_type['appliance_preferences']['cpu']
                  new_dev_mode_property_set.preference_cpu = nil if old_development_appliance_type['appliance_preferences']['cpu'] = 0.0
                end
                old_development_appliance_type['port_mappings'].each do |old_port_mapping|
                  new_port_mapping_template = build_port_mapping_template(old_port_mapping,
                    old_development_appliance_type['endpoints'].present? ? old_development_appliance_type['endpoints'].select{|endp| endp['port'] == old_port_mapping['port']} : [])
                  new_port_mapping_template.dev_mode_property_set = new_dev_mode_property_set
                  new_dev_mode_property_set.port_mapping_templates << new_port_mapping_template
                end
                new_dev_mode_property_set.appliance = new_appliance
                new_appliance.dev_mode_property_set = new_dev_mode_property_set
              end

              new_vm = VirtualMachine.find_by(id_at_site: old_vms['vms_id'].gsub('cyfronet-folsom-vm-','').gsub('amazon-vm-',''))
              if new_vm
                mapping_holder = (mode == 'development') ? new_appliance.dev_mode_property_set : new_appliance.appliance_type                  
                old_vms['internal_port_mappings'].each do |old_internal_port_mapping|
                  puts "All PMTs: #{mapping_holder.port_mapping_templates.map(&:target_port)}."
                  puts "Searching for: #{old_internal_port_mapping}."
                  pmt = mapping_holder.port_mapping_templates.detect{|p| p.target_port == old_internal_port_mapping['vm_port']}
                  puts "Found PMT: #{pmt}."
                  new_port_mapping = PortMapping.new(port_mapping_template: pmt, public_ip: old_internal_port_mapping['headnode_ip'], source_port: old_internal_port_mapping['headnode_port'], virtual_machine: new_vm)
                  pmt.port_mappings << new_port_mapping
                  puts pmt.port_mappings.first.errors.to_json.to_s unless pmt.valid?  
                end
                puts " ------- Setup a relation to Virtual Machine #{new_vm.id_at_site}."
                new_appliance.virtual_machines << new_vm
                puts new_vm.port_mappings.first.errors.to_json.to_s unless new_vm.valid? 
              else
                raise Exception.new(" ----- [ERROR] Virtual Machine of id [#{old_vms['vms_id']}] not found among current VMs.")
              end

              new_appliance_set.appliances << new_appliance
              puts " --- Is new appliance valid?: #{new_appliance.valid?}."
            end
          end

          user.appliance_sets << new_appliance_set
        end
        user.save
        puts " --- Is new user valid?: #{user.valid?}."
      end    
    end
  end
  puts " --- Bypassing Workflows/ApplianceSets setup." unless MIGRATE_WORKFLOWS


end

