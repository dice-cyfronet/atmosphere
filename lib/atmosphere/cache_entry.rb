module Atmosphere
  class CacheEntry
    attr_reader :value

    def initialize(value, expiration_period = 5.minutes)
      @value = value
      @expiration_period = expiration_period
      @timestamp = Time.now
    end

    def valid?
      (Time.now - @timestamp) < @expiration_period
    end
  end

  class NullCacheEntry
    def valid?
      false
    end

    def value
      nil
    end
  end
end
