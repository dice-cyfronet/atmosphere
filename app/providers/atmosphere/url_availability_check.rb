class UrlAvailabilityCheck

  def is_available(url, timeout = 3)
      connection = Faraday.new url, :ssl => {:verify => false}
      response = connection.get do |req|
        req.url url
        req.options.timeout = timeout
        req.options.open_timeout = timeout
      end
      Rails.logger.debug { "Status for url #{url} is #{response.status}" }

      !Air.config.url_check.unavail_statuses.include?(response.status)
  rescue
    Rails.logger.debug { "Status for url #{url} cannot be checked" }
    false
  end
end
