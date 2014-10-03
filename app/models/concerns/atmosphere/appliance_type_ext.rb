module Atmosphere::ApplianceTypeExt
  extend ActiveSupport::Concern

  included do
    include EscapeXml

    belongs_to :security_proxy,
      class_name: 'Atmosphere::SecurityProxy'

    after_create :publish_metadata, if: :publishable?
    after_destroy :remove_metadata, if: 'metadata_global_id and publishable?'
    around_update :manage_metadata
  end

  # This method is used to produce XML document that is being sent to the Metadata Registry
  def as_metadata_xml
    optional_elements = metadata_global_id ?
        "<globalID>#{metadata_global_id}</globalID>" :
        "<metadataCreationDate>#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}</metadataCreationDate>
         <category>None</category>"

    <<-MD_XML.strip_heredoc
    <resource_metadata>
      <atomicService>
        <localID>#{id}</localID>
        <name>#{esc_xml name}</name>
        <type>AtomicService</type>

        <description>#{esc_xml description}</description>
        <metadataUpdateDate>#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}</metadataUpdateDate>
        <creationDate>#{created_at.strftime('%Y-%m-%d %H:%M:%S')}</creationDate>
        <updateDate>#{updated_at.strftime('%Y-%m-%d %H:%M:%S')}</updateDate>
        <author>#{esc_xml(author.login) if author}</author>
        <development>#{visible_to == 'developer' ? 'true' : 'false'}</development>

        #{optional_elements}

        <endpoints>
          #{port_mapping_templates.map(&:endpoints).flatten.map(&:as_metadata_xml).join}
        </endpoints>
      </atomicService>
    </resource_metadata>
    MD_XML
  end

  def metadata_changed?
    name_changed? or description_changed? or visible_to_changed? or user_id_changed?
  end

  def update_metadata
    metadata_repo_client.update_appliance_type self
  end

  # METADATA lifecycle methods

  # Check if we need to publish/update/unpublish metadata regarding this AT, if so, perform the task
  def manage_metadata
    was_published = ((visible_to_was == 'all') or (visible_to_was == 'developer'))
    important_change = metadata_changed?

    yield

    if metadata_global_id and was_published and publishable?
      update_metadata if important_change
    elsif metadata_global_id and was_published
      remove_metadata
    elsif publishable?
      publish_metadata
    end
  end

  def remove_metadata
    metadata_repo_client.delete_metadata self
    update_column(:metadata_global_id, nil) unless destroyed?
  end

  def publish_metadata
    mgid = metadata_repo_client.publish_appliance_type self
    update_column(:metadata_global_id, mgid) if mgid
  end

  def metadata_repo_client
    Atmosphere::MetadataRepositoryClient.instance
  end
end