# This is a service class used to enforce billing rules on each Appliance registered in the system
class BillingCharger

  def initialize
    @appliance_prepayment_interval = 3600 # Bill appliances for this many seconds in advance.
  end

  # charge_appliances should be invoked once per a set period of time
  # This method charges for all active appliances (i.e. those which are listed as "satisfied")
  # It also decides what to do with appliances whose funding has expired.
  def self.bill_all_appliances
    Appliance.all.each do |appl|
      logger.debug("Billing appliance #{appl.id}...")

      if appl.prepaid_until.blank?
        # This should not happen - it means that we do not know when this appliance will run out of funds. Therefore we cannot meaningfully bill it again and must return an error.
        logger.error("Unable to determine current payment validity date for appliance #{appl.id}. Skipping.")
        appl.billing_state = :error
        appl.save
        next
      elsif appl.state != 'satisfied'
        # The appliance is not satisfied and therefore unusable - we should not charge for it.
        logger.warn("Appliance #{appl.id} is not satisfied. Skipping.")
        next
      end

      # Figure out how long this appliance can continue to run without being billed again.
      current_time = Time.now
      billing_interval = (current_time - appl.last_billing) # This will return time in seconds

      unless billing_interval < 0
        # The appliance is still prepaid - nothing to be done.
        logger.debug("Appliance #{appl.id} is prepaid until #{appl.prepaid_until}. Nothing to be done.")
      else
        # Bill the hell out of this appliance! :)
        logger.debug("Billing appliance #{appl.id} for #{billing_interval} hours of use.")
        # Open a transaction to avoid race conditions etc.
        ActiveRecord::Base.transaction do
          amount_due = calculate_charge_for_appliance(appl, current_time)
          # Check if there are sufficient funds
          if amount_due > appl.fund.balance-appl.fund.overdraft_limit
            # We've run out of funds. This appliance cannot be paid for. Flagging it as expired.
            logger.warn("The balance of fund #{fund.id} is insufficient to cover continued operation of appliance #{appl.id}. Flagging appliance as expired.")
            appl.billing_state = 'expired' # A separate method will be used to clean up all expired appliances according to their funds' termination policies
            appl.save
          else
            appl.fund.balance -= amount_due
            appl.prepaid_until = current_time+@appliance_prepayment_interval
            appl.last_billed = current_time
            appl.billing_state=:prepaid
            unless appl.save
              logger.error("ERROR: Unable to update appliance #{appl.id} with billing data.")
            else
              # Write to log.
              log = BillingLog.new(username: appl.appliance_set.user.login, appliance: appl.id.to_s+'---'+appl.name, fund: appl.fund.name, actor: "bill_all_appliances", amount_billed: amount_due)
            end
          end
        end
      end
    end

  end

  # This method calculates the amount which should be billed to a specific appliance on billing_time.
  # It does not actually incur the charge, merely returns the appropriate information.
  def self.calculate_charge_for_appliance(appl, billing_time)
    # By default, the billing process should extend the validity of the appliance until now+1.hour.
    billable_time = ((billing_time - appl.prepaid_until)/@advance_prepayment_interval) + 1.0 # Time in hours

    amount_due = 0.0

    # Iterate over appliance vms (there can be many, if the appliance is shared)
    appl.virtual_machines.each do |vm|
      # Find out how many appliances are using this VM and split costs equally
      hourly_charge = (vm.virtual_machine_flavor.hourly_cost/vm.appliances.count).round #TODO: figure out if we should limit this to appliances with billing_state == :prepaid
      logger.debug("Calculated hourly charge for using VM #{vm.id} is #{hourly_charge}. This VM currently has #{vm.appliances.count} appliances using it.")
      charge = (hourly_charge*billable_time).round
      logger.debug("Total estimated cost of using VM #{vm.id} over a period of #{billable_time} hours is #{charge}")
      amount_due += charge
    end

    logger.debug("Total estimated charge for using Appliance #{appl.id} over a period of #{billable_hours} hours is #{amount_due}")

    # Return amount due
    amount_due
  end

  # This scans for :expired appliances and figures out what to do with the underlying VMs, following fund policies
  def self.apply_funding_policy
    VirtualMachine.where(managed_by_atmosphere: true).all.each do |vm|
      # If this VM has at least one prepaid appliance, it must not be touched. For safety's sake, we will also not touch appliances whose billing state is flagged as erroneous
      if vm.appliances.select {|appl| [:prepaid, :error].include? appl.billing_state}.count > 0
        # Do nothinig
      # If this VM has at least one appliance whose funding policy states 'no action' then do nothing.
      elsif vm.appliances.select {|appl| appl.fund.termination_policy == "no_action"}.count > 0
        # Do nothing
      # If this VM has at least one appliance whose funding policy states 'suspend' then shut down the VM without deleting it
      elsif vm.appliances.select {|appl| appl.fund.termination_policy == "suspend"}.count > 0
        # TODO: Ask TB how to suspend this VM
      # Else check again that all of this vm's appliances' funding policies state 'delete' and if so, delete the VM
      elsif vm.appliances.select {|appl| appl.fund.termination_policy == "delete"}.count == vm.appliances.count
        # TODO: Ask TB how to delete this VM
      else
        logger.error("Unable to figure out what to do with vm #{vm.id}. This probably indicates an error in BillingCharger::apply_funding_policy. Please report this to PN.")
        # Leave this VM as is, for safety's sake.
      end
    end

  end

end

