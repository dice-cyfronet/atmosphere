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
    # message is written to billing logs
    # apply_prepayment determines whether the appliance should be prepaid (false when shutting down appliance)
    def self.bill_appliance(appl, billing_time, message, apply_prepayment = true)
      if appl.prepaid_until.blank?
        # This should not happen - it means that we do not know when this appliance will run out of funds. Therefore we cannot meaningfully bill it again and must return an error.
        Rails.logger.error("Unable to determine current payment validity date for appliance #{appl.id}. Skipping.")
        BillingLog.new(timestamp: Time.now.utc, user: appl.appliance_set.user, appliance: appl.id.to_s+'---'+(appl.name.blank? ? 'unnamed_appliance' : appl.name), fund: appl.fund.name, message: "Unable to determine current payment validity date for appliance.", actor: "bill_appliance", amount_billed: 0).save
        appl.billing_state = "error"
        appl.save
        raise Atmosphere::BillingException.new(message: "Unable to determine current payment validity date for appliance #{appl.id}")
      else
        # Figure out how long this appliance can continue to run without being billed again.
        billing_interval = (billing_time - appl.prepaid_until) # This will return time in seconds
        if billing_interval < 0
          # The appliance is still prepaid - nothing to be done.
          Rails.logger.debug("Appliance #{appl.id} is prepaid until #{appl.prepaid_until}. Nothing to be done.")
        else
          # Bill the hell out of this appliance! :)
          Rails.logger.debug("Billing appliance #{appl.id} for #{(billing_interval/3600)} hours of use.")
          # Open a transaction to avoid race conditions etc.
          ActiveRecord::Base.transaction do
            amount_due = calculate_charge_for_appliance(appl, billing_time, apply_prepayment)
            # Check if there are sufficient funds
            if (amount_due > appl.fund.balance-appl.fund.overdraft_limit)
              # We've run out of funds. This appliance cannot be paid for. Flagging it as expired.
              Rails.logger.warn("The balance of fund #{appl.fund.id} is insufficient to cover continued operation of appliance #{appl.id} (current balance: #{appl.fund.balance}; overdraft limit: #{appl.fund.overdraft_limit}; calculated charge: #{amount_due}). Flagging appliance as expired.")
              BillingLog.new(timestamp: Time.now.utc, user: appl.appliance_set.user, appliance: appl.id.to_s+'---'+(appl.name.blank? ? 'unnamed_appliance' : appl.name), fund: appl.fund.name, message: "Funding expired for this appliance.", actor: "bill_appliance", amount_billed: 0).save
              appl.billing_state = "expired" # A separate method will be used to clean up all expired appliances according to their funds' termination policies
              appl.save
            else
              Rails.logger.debug("Applying charge of #{amount_due} to appliance #{appl.id} and deducting it from balance of fund #{appl.fund.id}.")
              appl.fund.balance -= amount_due
              appl.fund.save
              appl.amount_billed += amount_due
              appl.prepaid_until = billing_time+(apply_prepayment ? @appliance_prepayment_interval : 0)
              appl.last_billing = billing_time
              appl.billing_state = "prepaid"
              appl.save
              if appl.errors.blank?
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

    # This method calculates the amount which should be billed to a specific appliance on billing_time.
    # It does not actually incur the charge, merely returns the appropriate information.
    # billing_time specifies when the billing action is actually performed
    # apply_prepayment determines whether the method should include prepayment period (of length specified in @appliance_prepayment_interval)
    # - This is usually true, but will be false when calculating final charge for an appliance which is being shut down.
    def self.calculate_charge_for_appliance(appl, billing_time, apply_prepayment = true)
      # By default, the billing process should extend the validity of the appliance until now+1.hour.
      billable_time = self.calculate_billable_time(appl, billing_time, apply_prepayment)

      amount_due = 0

      # Iterate over appliance vms (there can be many, if the appliance is shared)
      appl.virtual_machines.each do |vm|
        # Find out how many appliances are using this VM and split costs equally
        hourly_charge = (vm.virtual_machine_flavor.hourly_cost/vm.appliances.count).round #TODO: figure out if we should limit this to appliances with billing_state == :prepaid
        Rails.logger.debug("Calculated hourly charge for using VM #{vm.id} is #{hourly_charge}. This VM currently has #{vm.appliances.count} appliances using it.")
        charge = (hourly_charge*billable_time).round
        amount_due += charge
      end
      # Return amount due
      amount_due
    end

    # This scans for :expired appliances and figures out what to do with the underlying VMs, following fund policies
    def self.apply_funding_policy
      VirtualMachine.where(managed_by_atmosphere: true).all.each do |vm|
        # If this VM has at least one prepaid appliance, it must not be touched. For safety's sake, we will also not touch appliances whose billing state is flagged as erroneous
        if vm.appliances.select {|appl| ['prepaid', 'error'].include? appl.billing_state}.count > 0
          # Do nothing
          Rails.logger.debug("Leaving VM #{vm.id} unchanged because it is used by a prepaid appliance.")
        # If this VM has at least one appliance whose funding policy states 'no action' then do nothing.
        elsif vm.appliances.select {|appl| appl.fund.termination_policy == 'no_action'}.count > 0
          # Do nothing
          Rails.logger.debug("Leaving VM #{vm.id} unchanged -- there are no prepaid appliances using it but the corresponding fund termination policy is 'no_action'.")
        # If this VM has at least one appliance whose funding policy states 'suspend' then shut down the VM without deleting it
        elsif vm.appliances.select {|appl| appl.fund.termination_policy == 'suspend'}.count > 0
          # TODO: Ask TB how to suspend this VM
          Rails.logger.debug("Suspending VM #{vm.id} -- there are no prepaid appliances using it and the corresponding fund termination policy is 'suspend'.")
        # Else check again that all of this vm's appliances' funding policies state 'delete' and if so, delete the VM
        elsif vm.appliances.select {|appl| appl.fund.termination_policy == 'delete'}.count == vm.appliances.count
          # TODO: Ask TB how to delete this VM
          Rails.logger.debug("Deleting VM #{vm.id} -- there are no prepaid appliances using it and the corresponding fund termination policy is 'delete'.")
        else
          Rails.logger.error("Unable to figure out what to do with vm #{vm.id}. This probably indicates an error in BillingCharger::apply_funding_policy. Please report this to PN.")
          # Leave this VM as is, for safety's sake.
        end
      end
    end

    def self.calculate_billable_time(appliance, billing_time, apply_prepayment)
      ((billing_time - appliance.prepaid_until) + (apply_prepayment ? @appliance_prepayment_interval : 0))/3600 # Time in hours
    end

    # Determines whether this appliance can afford to use a given VM (which may be shared)
    # Requires this appliance's fund to be bound to the VM's compute_site
    def self.can_afford_vm?(appliance, vm)
      if appliance.fund.blank?
        raise Atmosphere::BillingException.new(message: "can_afford_vm? invoked on an appliance (with id #{appliance.id}) which has no fund assigned. Unable to proceed.")
      end
      billable_time = self.calculate_billable_time(appliance, Time.now.utc, true)
      amt_due = (billable_time*(vm.virtual_machine_flavor.hourly_cost)/(vm.appliances.count+1)).round
      if amt_due <= (appliance.fund.balance-appliance.fund.overdraft_limit) and appliance.fund.compute_sites.include? vm.compute_site
        true
      else
        false
      end
    end

    # Determines whether this appliance can afford to fully use a VM of a given flavor (which may not be spawned yet)
    # Requires this appliance's fund to be bound to the flavor's compute site
    def self.can_afford_flavor?(appliance, flavor)
      if appliance.fund.blank?
        raise Atmosphere::BillingException.new(message: "can_afford_flavor? invoked on an appliance (with id #{appliance.id}) which has no fund assigned. Unable to proceed.")
      end
      billable_time = self.calculate_billable_time(appliance, Time.now.utc, true)
      amt_due = (billable_time*(flavor.hourly_cost)).round
      if amt_due <= (appliance.fund.balance-appliance.fund.overdraft_limit) and appliance.fund.compute_sites.include? flavor.compute_site
        true
      else
        false
      end
    end
  end
end
