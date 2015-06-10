Atmosphere.setup do |config|
  # If user credentials should be delegated into spawned VM than delegated
  # auth value can be used. It will automatically inject into every initial
  # configuration instance parameter with delegation_key value as a key
  # and result of delegate_auth method implemented in
  # /app/controllers/concerns/api/*/appliances_controller_ext.rb.
  #
  # config.delegation_initconf_key = nil

  # List of additional resources which should be presented while login
  # as admin user. List should be namespaced with router name. For main
  # rails application use following format:
  #
  #  {
  #    main_app: { AdditionalResourceViewsToShow }
  #  }
  #
  # config.admin_entites_ext = {
  #   main_app: [ AdditionalResourceViewsToShow ]
  # }

  # PDP class for defining which Appliance Types user is able to start in
  # development, production mode and which Appliance Types user is able to
  # manage.
  #
  # config.at_pdp_class

  # Regexp used to extract dynamic parameters from initial configuration
  # template payload. For example if default configuration is used
  # (<tt>/\#{\w*}/</tt> regexp and <tt>2..-2</tt> range) than from following
  # payload:
  #  hello #{name}
  # `name` variable will be extracted and reated as dynamic parameter
  #
  # config.config_param.regexp = /\#{\w*}/
  # config.config_param.range = 2..-2

  # Endpoint monitoring worker configuration. `unavail_statuses` table is used
  # to determine when endpoint should be treated as unavailable or available.
  # `pending`, `ok` and `lost` parameters define intervals (in seconds) for
  # checking endpoints in concrete state.
  #
  # config.url_monitoring.unavail_statuses = [502]
  # config.url_monitoring.pending = 10
  # config.url_monitoring.ok = 120
  # config.url_monitoring.lost = 15

  # Optimizer hints. `max_appl_no` determines how many appliances can reuse the
  # same VM when it is marked as sharable.
  #
  # config.optimizer.max_appl_no = 5

  # Cloud monitoring worker intervals for monitoring virtual machines (vm) and
  # virtual machine templates (vmt), flavors (flavor) and updating information
  # about virtual machines load (load)
  #
  # config.monitoring.intervals.vm = 30.seconds
  # config.monitoring.intervals.vmt = 1.minute
  # config.monitoring.intervals.flavor = 120.minutes
  # config.monitoring.intervals.load = 5.minutes

  # Delay for registering new VM inside Atmosphere. This delay was introduced
  # bacause mointoring is an asynchronous process which sometine was triggered
  # durring the process of spawning new appliance. As a conclusion we had a
  # race conditions of creating the same 2 elements in DB. Default 2 seconds
  # delay solves this problem.
  #
  # config.childhood_age = 2

  # Protection from deleting very young Virtyal Machines and Templates from
  # Atmosphere database. It was introduced because monitoring is an asynchronous
  # process which lead to race condition between deleting unused VM/VMT and
  # assigning them into Appliance/Appliance Type. 300 seconds delay solves this
  # issue.
  #
  # config.cloud_object_protection_time = 300

  # Period in which Template can be automaticaly assigned into Appliance Type,
  # version can be set to origin VMT version (this mechanism is used while
  # migrating VMT into atnother compute site) and `manage_by_atmosphere` can
  # be set to true (when VMT is assigned to Appliance Type).
  #
  # config.vmt_at_relation_update_period = 2

  # Interval for cloud clients (in hours).
  #
  # config.cloud_client_cache_time = 8

  # Defines the class of monitoring client that handles communication with
  # external monitoring system. Monitoring client can be used to:
  #   - registered virtual machines in external monitoring system when they
  #     are instantiated.
  #   - unregister virtual machines when they are destroyed.
  #   - get load metrics for virtual machines.
  #
  # Possible values:
  #   - Atmosphere::Monitoring::NullClient.new phony client that does nothing.
  #
  # config.monitoring_client = Atmosphere::Monitoring::NullClient.new

  # Defines the class of metric store client that handles communication with
  # external system used for storing virtual machine load metrics.
  #
  # Possible values:
  #   - Atmosphere::Monitoring::NullMetricsStore.new - phony client that
  #     does nothing.
  #
  # config.metrics_store = Atmosphere::Monitoring::NullMetricsStore.new

  # Application version shown on Atmosphere administration pages.
  #
  # config.app_version = 'my_version'

  # Atmosphere uses cancan to authorize user. By default it register
  # `Atmosphere::Ability` class in cancan. If you want to extend it than
  # create new Ability class which extends `Atmosphere::Ability` and set
  # this new class name as `ability_class` parameter value.
  #
  # config.ability_class = 'Atmosphere::Ability'

  # Password for vm instantiated at Azure (ssh keys are not suported)
  # By default azure_vm_password should be defined in air.yml
  # config.azure_vm_password = Settings.azure_vm_password

  # Sudoer user login at azure vms
  # By default azure_vm_password should be defined in air.yml
  # config.azure_vm_user = Settings.azure_vm_user
end
