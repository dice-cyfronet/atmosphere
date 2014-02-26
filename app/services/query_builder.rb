class QueryBuilder

  DEFAULT_LIMIT = 20

  def defaults
    {
        :output => "extend",
        :limit => DEFAULT_LIMIT
    }
  end

  def add_params(param)
    if (param.is_a? Hash)
       @added_params = (@added_params || {}).merge(param)
    end
    self
  end

  def add_filter(filter)
    if (filter.is_a? Hash)
      @filters = (@filters || {}).merge(filter)
    end
    self
  end

  def build_get(entity)
    {
        :method => "#{entity}.get",
        :params => build_params
    }
  end

  private

  def build_params
    params = defaults.merge(@added_params || {})
    if @filters
      params[:filter] = params[:filter] ? params[:filter].merge(@filters) : @filters
    end
    params
  end

end