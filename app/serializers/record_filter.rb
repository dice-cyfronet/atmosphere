
module RecordFilter
  extend ActiveSupport::Concern

  module ClassMethods

    def page(params = {}, scope)
      page_with_options RecordFilterOptions.new(self, params, scope)
    end

    def page_with_options(options)
      page = options.scope_with_filters.paginate(
          page: options.page,
          per_page: options.page_size
      )
      page
    end

    def serializable_filters
      @serializable_filters
    end

    def can_filter_by(*attributes)
      attributes.each do |attribute|
        @serializable_filters ||= []
        @serializable_filters << attribute.to_sym
      end
    end

    def filterable_by
      filters = [self.model_class.primary_key.to_sym]
      filters += self.model_class.reflect_on_all_associations(:belongs_to).map(&:foreign_key).map(&:to_sym)

      filters += @serializable_filters if @serializable_filters
      filters.uniq
    end

  end
end