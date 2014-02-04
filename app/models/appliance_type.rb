# == Schema Information
#
# Table name: appliance_types
#
#  id                :integer          not null, primary key
#  name              :string(255)      not null
#  description       :text
#  shared            :boolean          default(FALSE), not null
#  scalable          :boolean          default(FALSE), not null
#  visible_to        :string(255)      default("owner"), not null
#  preference_cpu    :float
#  preference_memory :integer
#  preference_disk   :integer
#  security_proxy_id :integer
#  user_id           :integer
#  created_at        :datetime
#  updated_at        :datetime
#

class ApplianceType < ActiveRecord::Base
  extend Enumerize
  include EscapeXml

  belongs_to :security_proxy
  belongs_to :author, class_name: 'User', foreign_key: 'user_id'

  validates_presence_of :name, :visible_to
  validates_uniqueness_of :name

  enumerize :visible_to, in: [:owner, :developer, :all]

  validates :visible_to, inclusion: %w(owner developer all)
  validates :shared, inclusion: [true, false]
  validates :scalable, inclusion: [true, false]

  validates :preference_memory, numericality: { only_integer: true, greater_than_or_equal_to: 0, allow_nil: true }
  validates :preference_disk, numericality: { only_integer: true, greater_than_or_equal_to: 0, allow_nil: true }
  validates :preference_cpu, numericality: { greater_than_or_equal_to: 0.0, allow_nil: true }

  has_many :appliances, dependent: :destroy
  has_many :port_mapping_templates, dependent: :destroy
  has_many :appliance_configuration_templates, dependent: :destroy
  has_many :virtual_machine_templates

  scope :def_order, -> { order(:name) }
  scope :active, -> { joins(:virtual_machine_templates).where(virtual_machine_templates: {state: :active}) }
  scope :inactive, -> { where("id NOT IN (SELECT appliance_type_id FROM virtual_machine_templates WHERE state = 'active')") }

  before_destroy :store_vmts
  after_destroy :delete_vmts

  def destroy(force = false)
    if !force and has_dependencies?
      errors.add :base, "#{name} cannot be destroyed because other users have running instances of this application."
      return false
    end
    super()  # Parentheses required NOT to pass 'force' as an argument (not needed in Base.destroy)
  end

  def has_dependencies?
    # TODO temporary removing this check for PN request
    #virtual_machine_templates.present? or
    appliances.present?
  end

  def author_name
    author ? author.login : 'anonymous'
  end

  def self.create_from(appliance, overwrite = {})
    at = ApplianceType.new appliance_type_attributes(appliance, overwrite)
    PmtCopier.copy(appliance.dev_mode_property_set).each do |pmt|
      pmt.appliance_type = at
      at.port_mapping_templates << pmt
    end if appliance and appliance.dev_mode_property_set
    ActCopier.copy(appliance.appliance_type).each do |act|
      act.appliance_type = at
      at.appliance_configuration_templates << act
    end if appliance

    at
  end

  # This method is used to produce XML document that is being sent to the Metadata Registry
  def as_metadata_xml
    optional_elements = metadata_global_id ?
        "<globalID>#{metadata_global_id}</globalID>" :
        "<metadataCreationDate>#{Time.now.strftime('%Y-%m-%d')}</metadataCreationDate>"

    <<-MD_XML.strip_heredoc
      <AtomicService>
        <localID>#{id}</localID>
        <name>#{esc_xml name}</name>
        <type>AtomicService</type>
        <description>#{esc_xml description}</description>
        <metadataUpdateDate>#{Time.now.strftime('%Y-%m-%d')}</metadataUpdateDate>
        <creationDate>#{created_at.strftime('%Y-%m-%d')}</creationDate>
        <updateDate>#{updated_at.strftime('%Y-%m-%d')}</updateDate>
        <author>#{esc_xml(author.login) if author}</author>

        #{optional_elements}

        <endpoints>
          #{port_mapping_templates.map(&:endpoints).flatten.map(&:as_metadata_xml).join}
        </endpoints>
      </AtomicService>
    MD_XML
  end


  private

  def self.appliance_type_attributes(appliance, overwrite)
    if appliance and appliance.dev_mode_property_set
      params = appliance.dev_mode_property_set.attributes
      %w(id created_at updated_at appliance_id).each { |el| params.delete(el) }
    end
    params ||= {}

    overwrite_dup = overwrite.dup
    overwrite_dup.delete(:appliance_id)
    params.merge! overwrite_dup

    params
  end

  def store_vmts
    @vmts = virtual_machine_templates.to_a
  end

  def delete_vmts
    @vmts.each(&:destroy)
  end
end
