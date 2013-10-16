namespace :air do
  namespace :monitoring do
    task templates: :environment do
      ComputeSite.select(:id, :name).each do |cs|
        Rails.logger.debug "Creating templates monitoring task for #{cs.name}"
        VmTemplateMonitoringWorker.perform_async(cs.id)
      end
    end

    task vms: :environment do
      ComputeSite.select(:id, :name).each do |cs|
        Rails.logger.debug "Creating vms monitoring task for #{cs.name}"
        VmMonitoringWorker.perform_async(cs.id)
      end
    end
  end
end