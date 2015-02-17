# == Schema Information
#
# Table name: migration_jobs
#
#  id                          :integer          not null, primary key
#  appliance_type_id           :integer
#  compute_site_source_id      :integer
#  compute_site_destination_id :integer
#  status                      :text
#  created_at                  :datetime
#  updated_at                  :datetime
#  virtual_machine_template_id :integer
#

module Atmosphere
  class MigrationJob < ActiveRecord::Base
    belongs_to :appliance_type
    belongs_to :virtual_machine_template
    belongs_to :compute_site_source,
               class_name: 'ComputeSite',
               foreign_key: 'compute_site_source_id'
    belongs_to :compute_site_destination,
               class_name: 'ComputeSite',
               foreign_key: 'compute_site_destination_id'

    default_scope { order(updated_at: :desc) }
  end
end
