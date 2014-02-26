require "zabbixapi"

class ZabbixClient

  def initialize
    @config = Air.config.zabbix
  end

  def api
    @api || connect
  end

  def history(item_id)
    api.query(QueryBuilder.new.add_params(:itemids => item_id).build_get("history"))
  end

  def host(host_ident)
    qb = QueryBuilder.new
    if (host_ident.is_a? Integer)
      qb.add_params(:hostids => host_ident)
    else
      qb.add_filter(:name => host_ident)
    end
    hosts(qb)
  end

  def hosts(qb = QueryBuilder.new)
    api.query(qb.build_get("host"))
  end

  def host_id(host_name)
    id(host(host_name), "hostid")
  end

  def host_items(host_ident)
    host_id = (host_ident.is_a? Integer) ? host_ident : host_id(host_ident)
    raise "No such host '#{host_ident}'" if !host_id
    items(QueryBuilder.new.add_params(:hostids => host_id))
  end

  def templates(query_builder = QueryBuilder.new)
    api.query(query_builder.build_get("template"))
  end

  def template_id(template_name)
    api.templates.get_id(:host => template_name)
  end

  def template(template_ident)
    qb = QueryBuilder.new
    if (template_ident.is_a? Integer)
      qb.add_params(:templateids => template_ident)
    else
      qb.add_filter(:host => template_ident)
    end
    templates(qb)
  end

  def template_items(template_ident, extra_params = nil)
    template_id = (template_ident.is_a? Integer) ? template_ident : template_id(template_ident)
    raise "No such template '#{template_ident}'" if !template_id
    items(QueryBuilder.new.add_params(:templateids => template_id))
  end

  def items(qb = QueryBuilder.new)
    api.query(qb.build_get("item"))
  end

  def items_by_name(item_name)
    items(QueryBuilder.new.add_filter(:name => item_name))
  end

  def items_by_template(item_name, template_ident)
    template_id = (template_ident.is_a? Integer) ? template_ident : template_id(template_ident)
    items(QueryBuilder.new.add_params(:templateids => template_id).add_filter(:name => item_name))
  end

  def items_by_host(item_name, host_ident)
    host_id = (host_ident.is_a? Integer) ? host_ident : host_id(host_ident)
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