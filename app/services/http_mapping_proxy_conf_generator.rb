class HttpMappingProxyConfGenerator
  # PN 2013-10-21
  # Generates data structure required by ProxyConf to set up redirections
  # for all VMs running on a given CloudSite.
  # Parameterized by cloud site ID
  
  def run(compute_site_id)

    puts "Hello world"
    puts "cs id: #{compute_site_id}"

    cs = ComputeSite.find(compute_site_id)
    proxy_configuration = []
    
    if cs.blank?
      raise UnknownComputeSite, "Compute site with id #{compute_site_id.to_s} is unknown."
    end
    
    # comp. site has many VMs
    vms = cs.virtual_machines
    
    vms.each do |vm|
      
      # Each VM may belong to multiple appliances
      appliances = vm.appliances
      if appliances.blank?
        raise SchemaIntegrityException "VM with id #{vm.id} has no registered Appliances (expected at least one)."
      end
      
      appliances.each do |appl|
        
        # Each appliance may have multiple HTTP mappings
        http_mappings = appl.http_mappings
        http_mappings.each do |map|
          
          # Run schema validation (I'm being paranoid...)
          if map.port_mapping_template.blank?
            raise SchemaIntegrityException "HttpMapping with id #{map.id} has no matching PortMappingTemplate (expected exactly one)."   
          end
          if appl.appliance_set.blank?
            raise SchemaIntegrityException "Appliance with id #{appl.id} is not assigned to any ApplianceSet."
          end
          if appl.appliance_configuration_instance.blank?
            raise SchemaIntegrityException "Appliance with id #{appl.id} has no matching ApplianceConfigurationInstance (expected exactly one)."        
          end
          
          # Construct path object
          path = appl.appliance_set.id.to_s+'/'+appl.appliance_configuration_instance.id.to_s+'/'+map.port_mapping_template.id.to_s
          workers = []
          
          # Get all VMs for this appliance (this will produce duplicate records but is faster; we'll purge duplicates later)
          appl_vms = appl.virtual_machines
          appl.virtual_machines.each do |appl_vm|
            # Ignore if VM is not part of this compute site
            unless appl_vm.compute_site != cs
              workers << appl_vm.ip+":"+map.port_mapping_template.target_port.to_s
            end
          end

          # Spawn 0, 1 or 2 records for each mapping
          # (Depending on type - 0 for none, 1 for http or https, 2 for http_https)
          case map.port_mapping_template.application_protocol
          when 'none' then nil # Do nothing.
          when 'http' then
            proxy_configuration << {:path => path, :workers => workers, :type => 'http'}
          when 'https' then
            proxy_configuration << {:path => path, :workers => workers, :type => 'https'}
          when 'http_https' then
            proxy_configuration << {:path => path, :workers => workers, :type => 'http'}
            proxy_configuration << {:path => path, :workers => workers, :type => 'https'}
          else
            raise UnsupportedPortMappingProtocol, "Protocol type #{map.port_mapping_template.application_protocol} is not supported by Atmosphere."
          end # End case statement
        end # End iteration over http mappings
      end # End iteration over appliances
    end # End iteration over VMs    
    
    #proxy_configuration will contain duplicates when shared appliances are present, so...
    proxy_configuration.uniq
    
  end # End run(compute_site_id)



end