require "zabbixapi"

class ZabbixClient

  def initialize(api = nil)
    @config = Air.config.zabbix
    @api = api
  end

  def api
    @api || connect
  end

  def history(qb = QueryBuilder.new)
    api.query(qb.build_get("history"))
  end

  def host(host_ident)
    qb = QueryBuilder.new
    if (host_ident.is_a? Integer)
      qb.add_params(:hostids => host_ident)
    else
      qb.add_filter(:name => host_ident)
    end
    result = hosts(qb)
    raise "No such host '#{host_ident}'" if result.size == 0
    result
  end

  def hosts(qb = QueryBuilder.new)
    api.query(qb.build_get("host"))
  end

  def host_id(host_ident)
    host_id = (host_ident.is_a? Integer) ? host_ident : id(host(host_ident), "hostid")
    raise "No such host '#{host_ident}'" if !host_id
    host_id
  end

  def host_items(host_ident)
    items(QueryBuilder.new.add_params(:hostids => host_id(host_ident)))
  end

  def templates(query_builder = QueryBuilder.new)
    api.query(query_builder.build_get("template"))
  end

  def template_id(template_ident)
    template_id = (template_ident.is_a? Integer) ? template_ident : api.templates.get_id(:host => template_ident)
    raise "No such template '#{template_ident}'" if !template_id
    template_id
  end

  def template(template_ident)
    qb = QueryBuilder.new
    if (template_ident.is_a? Integer)
      qb.add_params(:templateids => template_ident)
    else
      qb.add_filter(:host => template_ident)
    end
    result = templates(qb)
    raise "No such template '#{template_ident}'" if result.size == 0
    result
  end

  def template_items(template_ident)
    items(QueryBuilder.new.add_params(:templateids => template_id(template_ident)))
  end

  def item(item_id)
    items(QueryBuilder.new.add_params(:itemids => item_id))
  end

  def items(qb = QueryBuilder.new)
    api.query(qb.build_get("item"))
  end

  def items_by_name(item_name)
    items(QueryBuilder.new.add_filter(:name => item_name))
  end

  def items_by_template(item_name, template_ident)
    items(QueryBuilder.new.add_params(:templateids => template_id(template_ident)).add_filter(:name => item_name))
  end

  def items_by_host(item_name, host_ident)
    host_id = (host_ident.is_a? Integer) ? host_ident : host_id(host_ident)
    raise "No such host '#{host_ident}'" if !host_id
    items(QueryBuilder.new.add_params(:hostids => host_id).add_filter(:name => item_name))
  end

  def id(result, id_key)
    id = nil
    if result
      result.each { |item| id = item[id_key].to_i if item[id_key] }
    end
    id
  end

  private

  def connect
    @api = ZabbixApi.connect(
        :url => @config.url,
        :user => @config.user,
        :password => @config.password
    )
  end

end