#
# Options for serializer record filter.
#
module Atmosphere
  class RecordFilterOptions
    attr_accessor :page, :page_size, :includes, :filters,
                  :serializer, :model_class, :scope, :include_links

    DEFAULT_PAGE_SIZE = 5

    def initialize(serializer, params = {}, scope = nil)
      params.symbolize_keys! if params.respond_to?(:symbolize_keys!)

      @params = params
      @serializer = serializer
      @model_class = serializer.model_class
      @filters = filters_from_params
      @scope = scope || model_class.send(:all)
      @include_links = true

      @page      = param_to_i(:page, default: 1)
      @page_size = param_to_i(:page_size)
      @includes  = param_to_sym_a(:includes, default: [])
    end

    def page?
      @page_size.nil?
    end

    def scope_with_filters
      scope_filter = {}
      @filters.keys.each do |filter|
        value = @filters[filter]
        value = value.split(',') if value.is_a?(String)
        scope_filter[filter] = value
      end

      @scope.where(scope_filter)
    end

    def filters_as_url_params
      @filters.sort.map { |k, v| "#{k}=#{v.join(',')}" }.join('&')
    end

    private

    attr_reader :params, :serializer

    def filters_from_params
      filters = {}
      serializer.filterable_by.each do |filter|
        [filter, "#{filter}s".to_sym].each do |key|
          filters[filter] = params[key].to_s.split(',') if params[key]
        end
      end
      filters
    end

    def param_to_i(key, options = {})
      params[key] ? params[key].to_i : options[:default]
    end

    def param_to_sym_a(key, options = {})
      if params[:includes]
        params[key].split(',').map(&:to_sym)
      else
        options[:default]
      end
    end
  end
end