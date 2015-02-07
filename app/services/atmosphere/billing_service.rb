# This is a service class used to enforce billing rules on each Appliance registered in the system
module Atmosphere
  class BillingService

    @appliance_prepayment_interval = 3600 # Bill appliances for this many seconds in advance.

    # charge_appliances should be invoked once per a set period of time
    # This method charges for all active appliances (i.e. those which are listed as "satisfied")
    # It also decides what to do with appliances whose funding has expired.
    def self.bill_all_appliances
      Appliance.all.each do |appl|
        begin
          bill_appliance(appl, Time.now.utc, "Mass billing operation.", true)
        rescue Atmosphere::BillingException => e
          # TODO: Communicate this to the user via MI. For safety's sake, leave this appliance alone.
          appl.billing_state = 'error'
          appl.save
        end
      end
    end

    # This method effects billing for a single appliance.
    # It works by iterating over this appliance's deployments and billing each one separately
    # A message is written to billing logs.
    # apply_prepayment determines whether the deployment should be prepaid
    # (false when shutting down appliance or deployment)
    def self.bill_appliance(appl, billing_time, message, apply_prepayment = true)
      appl.deployments.each do |dep|
        bill_deployment(dep, billing_time, message, apply_prepayment)
      end
    end


    def self.bill_deployment(dep, billing_time, message, apply_prepayment = true)
      appl = dep.appliance # Shorthand
      if dep.prepaid_until.blank?
        # This should not happen - it means that we do not know when this deployment will run out of funds.
        # Therefore we cannot meaningfully bill it again and must return an error.
        Rails.logger.error("Unable to determine current payment validity date for deployment #{dep.id} belonging to appliance #{appl.id}. Skipping.")
        BillingLog.new(timestamp: Time.now.utc, user: appl.appliance_set.user,
          appliance: "#{appl.id.to_s}---#{appl.name.blank? ? 'unnamed_appliance' : appl.name}",
          fund: appl.fund.name, message: "Unable to determine current payment validity date for deployment.",
          actor: "bill_appliance", amount_billed: 0).save
        dep.billing_state = "error"
        dep.save
        raise Atmosphere::BillingException.new(message: "Unable to determine current payment validity date for deployment #{dep.id} belonging to appliance #{appl.id}")
      else
        # Figure out how long this deployment can continue to run without being billed again.
        billing_interval = (billing_time - dep.prepaid_until) # This will return time in seconds
        if billing_interval < 0
          # The appliance is still prepaid - nothing to be done.
          Rails.logger.debug("Deployment #{dep.id} belonging to appliance #{appl.id} is prepaid until #{dep.prepaid_until}. Nothing to be done.")
        else
          # Bill the hell out of this deployment! :)
          Rails.logger.debug("Billing deployment #{dep.id} belonging to appliance #{appl.id} for #{billing_interval/3600} hours of use.")
          # Open a transaction to avoid race conditions etc.
          ActiveRecord::Base.transaction do
            amount_due = calculate_charge_for_deployment(dep, billing_time, apply_prepayment)
            # Check if there are sufficient funds
            if (amount_due > appl.fund.balance-appl.fund.overdraft_limit)
              # We've run out of funds. This deployment cannot be paid for. Flagging it as expired.
              Rails.logger.warn("The balance of fund #{appl.fund.id} is insufficient to cover continued operation of deployment #{dep.id} belonging to appliance #{appl.id} (current balance: #{appl.fund.balance}; overdraft limit: #{appl.fund.overdraft_limit}; calculated charge: #{amount_due}). Flagging deployment as expired.")
              BillingLog.new(timestamp: Time.now.utc, user: appl.appliance_set.user, appliance: appl.id.to_s+'---'+(appl.name.blank? ? 'unnamed_appliance' : appl.name), fund: appl.fund.name, message: "Funding expired for deployment #{dep.id}.", actor: "bill_appliance", amount_billed: 0).save
              # A separate method will be used to clean up all expired
              # deployments according to their funds' termination policies
              dep.billing_state = "expired"
              dep.save
            else
              Rails.logger.debug("Applying charge of #{amount_due} to deployment #{dep.id} belonging to appliance #{appl.id} and deducting it from balance of fund #{appl.fund.id}.")
              appl.fund.balance -= amount_due
              appl.fund.save
              appl.amount_billed += amount_due
              appl.last_billing = billing_time
              dep.prepaid_until = billing_time+(apply_prepayment ? @appliance_prepayment_interval : 0)
              dep.billing_state = "prepaid"
              # These should be saved together or not at all
              ActiveRecord::Base.transaction do
                appl.save
                dep.save
              end
              if dep.errors.blank? and appl.errors.blank?
                # Write success to log.
                BillingLog.new(timestamp: Time.now.utc, user: appl.appliance_set.user, appliance: appl.id.to_s+'---'+(appl.name.blank? ? 'unnamed_appliance' : appl.name), fund: appl.fund.name, message: message, actor: "bill_appliance", amount_billed: amount_due).save
              else
                Rails.logger.error("ERROR: Unable to update appliance #{appl.id} with billing data.")
                BillingLog.new(timestamp: Time.now.utc, user: appl.appliance_set.user, appliance: appl.id.to_s+'---'+(appl.name.blank? ? 'unnamed_appliance' : appl.name), fund: appl.fund.name, message: "Error saving appliance following update of billing information.", actor: "bill_appliance", amount_billed: 0).save
                raise Atmosphere::BillingException.new(message: "Unable to update appliance #{appl.id} with billing data.")
              end
            end
          end
        end
      end
    end

    # This method calculates the amount which should be billed to a specific deployment on billing_time.
    # It does not actually incur the charge, merely returns the appropriate information.
    # billing_time specifies when the billing action is actually performed
    # apply_prepayment determines whether the method should include prepayment period (of length specified in @appliance_prepayment_interval)
    # - This is usually true, but will be false when calculating final charge for a deployment which is being shut down.
    def self.calculate_charge_for_deployment(dep, billing_time, apply_prepayment = true)
      # By default, the billing process should extend the validity of the deployment until now+1.hour.
      billable_time = self.calculate_billable_time(dep, billing_time, apply_prepayment)

      vm = dep.virtual_machine # Shorthand
      # Find out how many appliances are using this VM and split costs equally
      os_family = dep.os_family
      #TODO: figure out if we should limit this to appliances with billing_state == :prepaid
      hourly_charge = (vm.virtual_machine_flavor.get_hourly_cost_for(os_family)/vm.appliances.count).round
      Rails.logger.debug("Calculated hourly charge for using VM #{vm.id} is #{hourly_charge}. This VM currently has #{vm.appliances.count} appliances using it.")

      # Return anticipated charge
      (hourly_charge*billable_time).round
    end

    # This scans for :expired deployments and figures out what to do with the underlying VMs, following fund policies
    def self.apply_funding_policy
      VirtualMachine.manageable.each do |vm|
        # If this VM has at least one prepaid deployment, it must not be touched.
        # For safety's sake, we will also not touch deployments whose billing state is flagged as erroneous
        if vm.deployments.select {|dep| ['prepaid', 'error'].include? dep.billing_state}.count > 0
          # Do nothing
          Rails.logger.debug("Leaving VM #{vm.id} unchanged because it is used by a prepaid deployment.")
        # If this VM has at least one deployment whose funding policy states 'no action' then do nothing.
        elsif vm.deployments.select {|dep| dep.appliance.fund.termination_policy == 'no_action'}.count > 0
          # Do nothing
          Rails.logger.debug("Leaving VM #{vm.id} unchanged -- there are no prepaid deployments using it but the corresponding fund termination policy is 'no_action'.")
        # If this VM has at least one deployment whose funding policy states 'suspend' then shut down the VM without deleting it
        elsif vm.deployments.select {|dep| dep.appliance.fund.termination_policy == 'suspend'}.count > 0
          # TODO: Ask TB how to suspend this VM
          Rails.logger.debug("Suspending VM #{vm.id} -- there are no prepaid deployments using it and the corresponding fund termination policy is 'suspend'.")
        # Else check again that all of this vm's deployments' funding policies state 'delete' and if so, delete the VM
        elsif vm.deployments.select {|dep| dep.appliance.fund.termination_policy == 'delete'}.count == vm.deployments.count
          # TODO: Ask TB how to delete this VM
          Rails.logger.debug("Deleting VM #{vm.id} -- there are no prepaid deployments using it and the corresponding fund termination policy is 'delete'.")
        else
          Rails.logger.error("Unable to figure out what to do with vm #{vm.id}. This probably indicates an error in BillingCharger::apply_funding_policy. Please report this to PN.")
          # Leave this VM as is, for safety's sake.
        end
      end
    end

    def self.calculate_billable_time(deployment, billing_time, apply_prepayment)
      ((billing_time - deployment.prepaid_until) + (apply_prepayment ? @appliance_prepayment_interval : 0))/3600 # Time in hours
    end

    # Determines whether this appliance can afford to use a given VM (which may be shared)
    # Requires this appliance's fund to be bound to the VM's compute_site
    def self.can_afford_vm?(appliance, vm)
      if appliance.fund.blank?
        raise Atmosphere::BillingException.new(message: "can_afford_vm? invoked on an appliance (with id #{appliance.id}) which has no fund assigned. Unable to proceed.")
      end

      # Check whether the target VM is already assigned to the appliance via deployments
      # If so, respect the prepayment period which *may* be present for this deployment
      deployments = appliance.deployments.where(virtual_machine_id: vm.id)
      if deployments.count > 0
        billable_time = self.calculate_billable_time(deployments.first, Time.now.utc, true)
      else
        # If this VM is not assigned to appliance then just assume def prepayment interval
        billable_time = @appliance_prepayment_interval/3600 # Time in hours
      end
      hourly_cost = vm.virtual_machine_flavor.get_hourly_cost_for(appliance.appliance_type.os_family)
      if hourly_cost.blank? # Will happen when there is a mismatch between AT ostype and flavor ostype
        return false
      end
      amt_due = ((billable_time*hourly_cost)/(vm.appliances.count+1)).round
      # Return boolean based on 2 conditions
      amt_due <= (appliance.fund.balance-appliance.fund.overdraft_limit) && (appliance.fund.compute_sites.include? vm.compute_site)
    end

    # Determines whether this appliance can afford to fully use a VM of a given flavor (which may not be spawned yet)
    # Requires this appliance's fund to be bound to the flavor's compute site
    def self.can_afford_flavor?(appliance, flavor)
      if appliance.fund.blank?
        raise Atmosphere::BillingException.new(message: "can_afford_flavor? invoked on an appliance (with id #{appliance.id}) which has no fund assigned. Unable to proceed.")
      end
      billable_time = @appliance_prepayment_interval/3600 # Time in hours

      puts "Getting hourly cost for appliance with fund balance #{appliance.fund.balance.to_s} and os_family #{appliance.appliance_type.os_family.inspect}"

      hourly_cost = flavor.get_hourly_cost_for(appliance.appliance_type.os_family)

      puts "Calculated hourly cost is #{hourly_cost.to_s}"

      if hourly_cost.blank? # Will happen when there is a mismatch between AT ostype and flavor ostype
        return false
      end
      amt_due = (billable_time*(hourly_cost)).round

      puts "Calculated amt due is #{amt_due.to_s}"

      if amt_due <= (appliance.fund.balance-appliance.fund.overdraft_limit) and
        appliance.fund.compute_sites.include? flavor.compute_site
        return true
      else
        return false
      end
    end

    #TODO document
    def self.can_afford_flavors?(appliance, flavors)
      #TODO implement
      true
    end

  end
end
