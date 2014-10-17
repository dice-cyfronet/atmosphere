require 'atmosphere/cache_entry'

module Atmosphere
  class CachedDelegator < Delegator
    def initialize(timeout, &block)
      @timeout = timeout
      @block = block
    end

    def __getobj__
      unless @cache_entry && @cache_entry.valid?
        @cache_entry = CacheEntry.new(@block.call, @timeout)
      end

      @cache_entry.value
    end

    def clean_cache!
      @cache_entry = nil
    end
  end
end