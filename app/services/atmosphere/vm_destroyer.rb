module Atmosphere
  class VmDestroyer
    delegate :errors, to: :virtual_machine

    def initialize(virtual_machine, appl_updater_class = Proxy::ApplianceProxyUpdater)
      @virtual_machine = virtual_machine
      @appl_updater_class = appl_updater_class
    end

    def destroy(delete_in_cloud = true)
      # to_a because we need to be sure appliances are
      # loaded before VM is destroyed.
      affected_appliances = virtual_machine.appliances.to_a
      virtual_machine.destroy(delete_in_cloud).tap do |destroyed|
        affected_appliances.each do |appl|
          appl_updater_class.new(appl).update
        end
      end
    end

    private

    attr_reader :virtual_machine, :appl_updater_class
  end
end