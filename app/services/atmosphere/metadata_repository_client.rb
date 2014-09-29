require 'rexml/document'

# Acts as a single facade to the Metadata Repository
# Used to publish, update and unpublish AIR data inside MR
module Atmosphere
  class MetadataRepositoryClient
    include Singleton

    # Publishes new AtomicService
    def publish_appliance_type(appliance_type)
      return nil unless can_write and appliance_type
      body = appliance_type.as_metadata_xml
      logme 'Publishing atomic service with the following XML:'
      logme body
      status, response = do_http(server_endpoint, :post, body)
      status ? logme("Response body: #{response.body}") : logme_problem
      status ? parse_response(response, '_global_id') : nil
    end

    # Updates present AtomicService
    def update_appliance_type(appliance_type)
      return nil unless can_write and appliance_type and appliance_type.metadata_global_id
      body = appliance_type.as_metadata_xml
      logme 'Updating atomic service with the following XML:'
      logme body
      status, response = do_http(server_endpoint + appliance_type.metadata_global_id.to_s, :put, body)
      status ? logme("Response body: #{response.body}") : logme_problem
      status ? parse_response(response, '_global_id') : nil
    end

    # Removes the given global_id from active metadata search results
    def delete_metadata(appliance_type)
      return unless can_write and appliance_type
      status, response = do_http(server_endpoint + appliance_type.metadata_global_id.to_s, :delete)
      status ? logme("Response body: #{response.body}") : logme_problem
      status
    end

    # Removes the MR entry regardless the fact it exists in our model or not; useful for sweeping the MR store
    def purge_metadata_key(metadata_global_id)
      return unless can_write
      status, response = do_http(server_endpoint + metadata_global_id, :delete)
      status ? logme("Response body: #{response.body}") : logme_problem
      status
    end

    # Gets all published, active AtomicServices globalID
    def get_active_global_ids(type = 'AtomicService')
      return unless can_read
      #status, response = do_http(server_endpoint + "filter?logicalExpression=type:#{type}%20AND%20status:active")
      status, response = do_http(server_endpoint + "facets/#{type}/status?value=active&numResults=99999")
      logme_problem unless status
      if status
        doc = REXML::Document.new response.body.to_s
        global_ids = []
        doc.elements.each("resource_metadata_list/resource_metadata/atomicService/globalID") { |element| global_ids << element.text }
        global_ids
      else
        nil
      end
    end


    private

    # Assumes the response is a correct HTTPSuccess body message.
    # Returns the XML element body for 'word' element name
    def parse_response(response, word)
      get_xml_content(response.body.to_s, word)
    end

    # Tests if the Server responsed with HTTPSuccess and if the operation itself was successful (the status attribute == "OK")
    # Returns: [is_ok, value]
    #   * when !is_ok, value may be either nil of server exaplanation of what happened (the failure message)
    #   * when is_ok (the API call is a success), value is nil
    def check_response_success(response)
      # NOTE: see other HTTPResponse cases: http://www.ensta-paristech.fr/~diam/ruby/online/ruby-doc-stdlib/libdoc/net/http/rdoc/classes/Net/HTTPResponse.html
      return [false,:access_problem] if response.nil?
      if (not response.kind_of?(Net::HTTPSuccess)) or response.kind_of?(Net::HTTPNoContent)
        logme "Application layer error in communication with Metadata server. Code (#{response.code})", true
        if response.class.body_permitted?
          logme response.body.to_s, true
        else
          logme "No response 'body' supplied.", true
        end
        return [false,:access_problem]
      end
      #status = get_attribute(response.body, "response", "status")
      #if status == "failed"
      #  cause = get_xml_content(response.body.to_s, "cause")
      #  logme "Metadata server API call failed. Cause: #{cause}. Full response body below."
      #  logme response.body
      #  return [false,cause]
      #end
      [true,nil]
    end

    def get_xml_content(body, marker)
      return nil if !body.include? marker
      body[/<#{marker}>.*<\/#{marker}>/][(marker.length+2)..-marker.length-4]
    end

    def get_attribute(body, element, attribute)
      body[/#{element}.*>/][/#{attribute}=".*"/][(attribute.length+2)..-2]
    end

    # Performs the low-lever HTTP API call
    # Returns: [is_ok, content]
    #   * when !is_ok, content contains nil or the explanation of the problem(s) encountered
    #   * when is_ok,  content contains the response HTTPS message
    def do_http(endpoint, method = :get, body = nil)
      logme "Performing HTTP [#{method}] call to endpoint [#{endpoint}]"

      uri = URI(endpoint)
      http = Net::HTTP.new(uri.host, uri.port)

      server_request = case method
        when :get
          path = uri.path
          path += '?' + uri.query if uri.query and !uri.query.empty?
          Net::HTTP::Get.new(path)
        when :post
          Net::HTTP::Post.new(uri.path)
        when :put
          Net::HTTP::Put.new(uri.path)
        when :delete
          Net::HTTP::Delete.new(uri.path)
      end
      server_request.add_field('Content-Type', 'application/xml') if method == :post or method == :put
      server_request.body = body if body != nil

      begin
        response = http.request(server_request)
        status, message = check_response_success(response)
        unless status
          raise "Unknown Metadata server communication protocol error (#{message})."
        end
        [true, response]
      rescue Exception => e
        logme 'Transport layer error in communication with MR.', true
        logme "Exception message: [#{e.message}]. Stacktrace:", true
        logme e.backtrace.inspect, true
        Raven.capture_exception(e, tags: { type: 'mds' })
        [false,:access_problem]
      end
    end


    def can_read
      Air.config.metadata[:remote_connect] and !Rails.env.test?
    end

    def can_write
      Air.config.metadata[:remote_connect] and Air.config.metadata[:remote_publish] and !Rails.env.test?
    end

    def server_endpoint
      # host firewall timeout testing example
      #'http://vphshare.atosresearch.eu:7777/metadata-retrieval/rest/metadata/'
      # wrong host API endpoint testing example
      #'http://vphshar.atosresearch.eu/metadata-retrieval/rest/metadata/'
      # wrong API endpoint shared key
      #'http://vphshare.atosresearch.eu/metadata-retrieva/rest/metadata/'

      # the correct value for production
      #'http://vphshare.atosresearch.eu/metadata-retrieval/rest/metadata/'
      Air.config.metadata[:registry_endpoint]
    end

    def logme_problem
      logme 'Problem with Metadata server communication. Ignoring.', true
    end

    def logme(mess, err = false)
      Rails.logger.info "[MetadataClient] #{'[ERROR]' if err} #{mess}."
    end
  end
end