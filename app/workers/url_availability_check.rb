class UrlAvailabilityCheck

  def is_available(url, timeout = 3)
    begin
      response = Faraday.get do |req|
        req.url url
        req.options.timeout = timeout
        req.options.open_timeout = timeout
      end
      Rails.logger.debug("Status for url #{url} is #{response.status}")
      if (response.status == 200)
        return true
      end
      return false
    rescue
      Rails.logger.debug("Status for url #{url} cannot be checked")
      return false
    end
  end

end